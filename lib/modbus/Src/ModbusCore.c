/* SPDX-License-Identifier: LGPL-2.1-only
 * Modbus.c
 *  Modbus RTU Master and Slave library for STM32 CUBE with FreeRTOS
 *  Created on: May 5, 2020
 *      Author: Alejandro Mera
 *      Adapted from https://github.com/smarmengol/Modbus-Master-Slave-for-Arduino
 *
 * Modified 2026-10-28 for NV-Migration: extracted portable PDU processing,
 * explicit capacities, strict validation and endian-independent words.
 * Derived from upstream 9c022fd2538edb5b53e2e07c98ebbe9a4685546c.
 * See ../UPSTREAM.md for function-level provenance and intentional changes.
 */
#include "ModbusCore.h"

#include <errno.h>
#include <string.h>

/* Upstream mb_region_t and get*Region retain per-type NULL fallback. */
typedef struct {
    uint16_t *data;
    uint16_t startAddress;
    uint16_t size;
} mb_region_t;

static mb_region_t getCoilsRegion(const mb_memory_t *map)
{
    mb_region_t region;
    if (map->u16coils != NULL) {
        region.data = map->u16coils;
        region.startAddress = map->u16coilsStartAdd;
        region.size = map->u16coilsNregs;
    } else {
        region.data = map->u16regs;
        region.startAddress = 0;
        region.size = map->u16regsize;
    }
    return region;
}

static mb_region_t getDIRegion(const mb_memory_t *map)
{
    mb_region_t region;
    if (map->u16discreteInputs != NULL) {
        region.data = map->u16discreteInputs;
        region.startAddress = map->u16discreteInputsStartAdd;
        region.size = map->u16discreteInputsNregs;
    } else {
        region.data = map->u16regs;
        region.startAddress = 0;
        region.size = map->u16regsize;
    }
    return region;
}

static mb_region_t getHRRegion(const mb_memory_t *map)
{
    mb_region_t region;
    if (map->u16holdingRegs != NULL) {
        region.data = map->u16holdingRegs;
        region.startAddress = map->u16holdingRegsStartAdd;
        region.size = map->u16holdingRegsNregs;
    } else {
        region.data = map->u16regs;
        region.startAddress = 0;
        region.size = map->u16regsize;
    }
    return region;
}

static mb_region_t getIRRegion(const mb_memory_t *map)
{
    mb_region_t region;
    if (map->u16inputRegs != NULL) {
        region.data = map->u16inputRegs;
        region.startAddress = map->u16inputRegsStartAdd;
        region.size = map->u16inputRegsNregs;
    } else {
        region.data = map->u16regs;
        region.startAddress = 0;
        region.size = map->u16regsize;
    }
    return region;
}

static uint16_t word(uint8_t high, uint8_t low)
{
    return (uint16_t)(((uint16_t)high << 8) | low);
}

static void putWord(uint8_t *out, uint16_t value)
{
    out[0] = (uint8_t)(value >> 8);
    out[1] = (uint8_t)value;
}

static bool bitRead(uint16_t value, unsigned int bit)
{
    return ((value >> bit) & 1u) != 0u;
}

static void bitWrite(uint16_t *value, unsigned int bit, bool state)
{
    uint16_t mask = (uint16_t)(1u << bit);
    if (state) {
        *value |= mask;
    } else {
        *value &= (uint16_t)~mask;
    }
}

static bool bitFunction(uint8_t function)
{
    return function == MB_FC_READ_COILS ||
           function == MB_FC_READ_DISCRETE_INPUT ||
           function == MB_FC_WRITE_COIL ||
           function == MB_FC_WRITE_MULTIPLE_COILS;
}

static uint16_t quantityLimit(uint8_t function)
{
    switch (function) {
    case MB_FC_READ_COILS:
    case MB_FC_READ_DISCRETE_INPUT:
        return 2000;
    case MB_FC_READ_REGISTERS:
    case MB_FC_READ_INPUT_REGISTER:
        return 125;
    case MB_FC_WRITE_COIL:
    case MB_FC_WRITE_REGISTER:
        return 1;
    case MB_FC_WRITE_MULTIPLE_COILS:
        return 1968;
    case MB_FC_WRITE_MULTIPLE_REGISTERS:
        return 123;
    default:
        return 0;
    }
}

static size_t dataBytes(uint8_t function, uint16_t quantity)
{
    return bitFunction(function) ? ((size_t)quantity + 7u) / 8u
                                 : (size_t)quantity * 2u;
}

static int buildException(uint8_t function, uint8_t exception,
                          uint8_t *reply, size_t capacity)
{
    if (capacity < 2u) {
        return -ENOSPC;
    }
    reply[0] = (uint8_t)(function | 0x80u);
    reply[1] = exception;
    return 2;
}

/* process_FC1/3/5/6/15/16 operate only after complete request validation. */
static int process_FC1(mb_region_t region, uint32_t start, uint16_t quantity,
                       uint8_t *reply)
{
    size_t bytes = dataBytes(MB_FC_READ_COILS, quantity);
    reply[1] = (uint8_t)bytes;
    memset(reply + 2, 0, bytes);
    for (uint16_t currentCoil = 0; currentCoil < quantity; ++currentCoil) {
        uint32_t coil = start + currentCoil;
        uint32_t currentRegister = coil / 16u;
        unsigned int currentBit = coil % 16u;
        if (bitRead(region.data[currentRegister], currentBit)) {
            reply[2u + currentCoil / 8u] |= (uint8_t)(1u << (currentCoil % 8u));
        }
    }
    return (int)(2u + bytes);
}

static int process_FC3(mb_region_t region, uint32_t start, uint16_t quantity,
                       uint8_t *reply)
{
    reply[1] = (uint8_t)(quantity * 2u);
    for (uint16_t i = 0; i < quantity; ++i) {
        putWord(reply + 2u + (size_t)i * 2u, region.data[start + i]);
    }
    return (int)(2u + (size_t)quantity * 2u);
}

static void process_FC5(mb_region_t region, uint32_t coil, uint16_t value)
{
    uint32_t currentRegister = coil / 16u;
    unsigned int currentBit = coil % 16u;
    bitWrite(&region.data[currentRegister], currentBit, value == 0xff00u);
}

static void process_FC6(mb_region_t region, uint32_t address, uint16_t value)
{
    region.data[address] = value;
}

static void process_FC15(mb_region_t region, uint32_t start, uint16_t quantity,
                         const uint8_t *pdu)
{
    unsigned int bits = 0;
    size_t frameByte = 6;
    for (uint16_t currentCoil = 0; currentCoil < quantity; ++currentCoil) {
        uint32_t coil = start + currentCoil;
        uint32_t currentRegister = coil / 16u;
        unsigned int currentBit = coil % 16u;
        bool state = bitRead(pdu[frameByte], bits);
        bitWrite(&region.data[currentRegister], currentBit, state);
        if (++bits > 7u) {
            bits = 0;
            ++frameByte;
        }
    }
}

static void process_FC16(mb_region_t region, uint32_t start, uint16_t quantity,
                         const uint8_t *pdu)
{
    for (uint16_t i = 0; i < quantity; ++i) {
        uint16_t value = word(pdu[6u + (size_t)i * 2u],
                              pdu[7u + (size_t)i * 2u]);
        region.data[start + i] = value;
    }
}

int mb_core_server(mb_memory_t *map, const uint8_t *pdu, size_t len,
                   uint8_t *reply, size_t capacity)
{
    if (map == NULL || pdu == NULL || reply == NULL || len == 0u) {
        return -EINVAL;
    }
    uint8_t function = pdu[0];
    uint16_t limit = quantityLimit(function);
    if (limit == 0u) {
        return buildException(function, 1, reply, capacity);
    }
    bool multiple = function == MB_FC_WRITE_MULTIPLE_COILS ||
                    function == MB_FC_WRITE_MULTIPLE_REGISTERS;
    if ((multiple && len < 6u) || (!multiple && len != 5u)) {
        return buildException(function, 3, reply, capacity);
    }
    uint16_t address = word(pdu[1], pdu[2]);
    uint16_t value = word(pdu[3], pdu[4]);
    bool single = function == MB_FC_WRITE_COIL || function == MB_FC_WRITE_REGISTER;
    uint16_t quantity = single ? 1u : value;
    if (quantity == 0u || quantity > limit ||
        (function == MB_FC_WRITE_COIL && value != 0u && value != 0xff00u)) {
        return buildException(function, 3, reply, capacity);
    }
    size_t bytes = dataBytes(function, quantity);
    if (multiple && (pdu[5] != bytes || len != 6u + bytes)) {
        return buildException(function, 3, reply, capacity);
    }

    mb_region_t region;
    switch (function) {
    case MB_FC_READ_COILS:
    case MB_FC_WRITE_COIL:
    case MB_FC_WRITE_MULTIPLE_COILS:
        region = getCoilsRegion(map);
        break;
    case MB_FC_READ_DISCRETE_INPUT:
        region = getDIRegion(map);
        break;
    case MB_FC_READ_INPUT_REGISTER:
        region = getIRRegion(map);
        break;
    default:
        region = getHRRegion(map);
        break;
    }
    if (region.data == NULL || address < region.startAddress ||
        (uint32_t)address + quantity > 65536u) {
        return buildException(function, 2, reply, capacity);
    }
    uint32_t offset = (uint32_t)address - region.startAddress;
    uint32_t end = offset + quantity;
    uint32_t required = bitFunction(function) ? (end + 15u) / 16u : end;
    if (required > region.size) {
        return buildException(function, 2, reply, capacity);
    }
    bool reading = function >= MB_FC_READ_COILS && function <= MB_FC_READ_INPUT_REGISTER;
    size_t responseLength = reading ? 2u + bytes : 5u;
    if (capacity < responseLength) {
        return -ENOSPC;
    }

    /* All shape, range and capacity checks precede both writes and responses. */
    switch (function) {
    case MB_FC_READ_COILS:
    case MB_FC_READ_DISCRETE_INPUT:
        reply[0] = function;
        return process_FC1(region, offset, quantity, reply);
    case MB_FC_READ_REGISTERS:
    case MB_FC_READ_INPUT_REGISTER:
        reply[0] = function;
        return process_FC3(region, offset, quantity, reply);
    case MB_FC_WRITE_COIL:
        process_FC5(region, offset, value);
        break;
    case MB_FC_WRITE_REGISTER:
        process_FC6(region, offset, value);
        break;
    case MB_FC_WRITE_MULTIPLE_COILS:
        process_FC15(region, offset, quantity, pdu);
        break;
    default:
        process_FC16(region, offset, quantity, pdu);
        break;
    }
    memmove(reply, pdu, 5u);
    return 5;
}

static int validateQuery(const modbus_t *query)
{
    if (query == NULL) {
        return -EINVAL;
    }
    uint16_t limit = quantityLimit(query->u8fct);
    if (limit == 0u) {
        return -ENOTSUP;
    }
    if (query->u16CoilsNo == 0u || query->u16CoilsNo > limit ||
        (uint32_t)query->u16RegAdd + query->u16CoilsNo > 65536u) {
        return -EINVAL;
    }
    size_t words = bitFunction(query->u8fct)
                       ? ((size_t)query->u16CoilsNo + 15u) / 16u
                       : query->u16CoilsNo;
    if (query->u16regCapacity < words) {
        return -ENOSPC;
    }
    if (query->u16reg == NULL) {
        return -EINVAL;
    }
    return 0;
}

int mb_core_build(const modbus_t *query, uint8_t *pdu, size_t capacity)
{
    int result = validateQuery(query);
    if (result != 0) {
        return result;
    }
    if (pdu == NULL) {
        return -EINVAL;
    }
    uint8_t function = query->u8fct;
    bool multiple = function == MB_FC_WRITE_MULTIPLE_COILS ||
                    function == MB_FC_WRITE_MULTIPLE_REGISTERS;
    size_t bytes = dataBytes(function, query->u16CoilsNo);
    size_t length = multiple ? 6u + bytes : 5u;
    if (capacity < length) {
        return -ENOSPC;
    }
    pdu[0] = function;
    putWord(pdu + 1, query->u16RegAdd);
    putWord(pdu + 3, query->u16CoilsNo);
    switch (function) {
    case MB_FC_WRITE_COIL:
        putWord(pdu + 3, query->u16reg[0] != 0u ? 0xff00u : 0u);
        break;
    case MB_FC_WRITE_REGISTER:
        putWord(pdu + 3, query->u16reg[0]);
        break;
    case MB_FC_WRITE_MULTIPLE_COILS:
        pdu[5] = (uint8_t)bytes;
        for (size_t i = 0; i < bytes; ++i) {
            pdu[6u + i] = (uint8_t)(query->u16reg[i / 2u] >> ((i % 2u) * 8u));
        }
        if (query->u16CoilsNo % 8u != 0u) {
            pdu[length - 1u] &= (uint8_t)((1u << (query->u16CoilsNo % 8u)) - 1u);
        }
        break;
    case MB_FC_WRITE_MULTIPLE_REGISTERS:
        pdu[5] = (uint8_t)bytes;
        for (uint16_t i = 0; i < query->u16CoilsNo; ++i) {
            putWord(pdu + 6u + (size_t)i * 2u, query->u16reg[i]);
        }
        break;
    default:
        break;
    }
    return (int)length;
}

/* Derived from get_FC1: alternate low/high bytes in packed uint16_t words. */
static void get_FC1(const modbus_t *query, const uint8_t *pdu)
{
    size_t bytes = dataBytes(query->u8fct, query->u16CoilsNo);
    for (size_t i = 0; i < bytes; ++i) {
        if (i % 2u != 0u) {
            query->u16reg[i / 2u] = word(pdu[i + 2u], (uint8_t)query->u16reg[i / 2u]);
        } else {
            query->u16reg[i / 2u] = pdu[i + 2u];
        }
    }
    unsigned int remaining = query->u16CoilsNo % 16u;
    if (remaining != 0u) {
        query->u16reg[query->u16CoilsNo / 16u] &= (uint16_t)((1u << remaining) - 1u);
    }
}

static void get_FC3(const modbus_t *query, const uint8_t *pdu)
{
    for (uint16_t i = 0; i < query->u16CoilsNo; ++i) {
        query->u16reg[i] = word(pdu[2u + (size_t)i * 2u], pdu[3u + (size_t)i * 2u]);
    }
}

int mb_core_parse(const modbus_t *query, const uint8_t *pdu, size_t len)
{
    int result = validateQuery(query);
    if (result != 0) {
        return result;
    }
    if (pdu == NULL) {
        return -EINVAL;
    }
    if (len < 2u) {
        return -EBADMSG;
    }
    uint8_t function = query->u8fct;
    if (pdu[0] == (uint8_t)(function | 0x80u)) {
        return len == 2u && pdu[1] != 0u ? pdu[1] : -EBADMSG;
    }
    if (pdu[0] != function) {
        return -EBADMSG;
    }
    if (function >= MB_FC_READ_COILS && function <= MB_FC_READ_INPUT_REGISTER) {
        size_t bytes = dataBytes(function, query->u16CoilsNo);
        if (len != bytes + 2u || pdu[1] != bytes) {
            return -EBADMSG;
        }
        if (bitFunction(function)) {
            get_FC1(query, pdu);
        } else {
            get_FC3(query, pdu);
        }
    } else {
        if (len != 5u || word(pdu[1], pdu[2]) != query->u16RegAdd) {
            return -EBADMSG;
        }
        uint16_t expected = query->u16CoilsNo;
        if (function == MB_FC_WRITE_COIL) {
            expected = query->u16reg[0] != 0u ? 0xff00u : 0u;
        } else if (function == MB_FC_WRITE_REGISTER) {
            expected = query->u16reg[0];
        }
        if (word(pdu[3], pdu[4]) != expected) {
            return -EBADMSG;
        }
    }
    return 0;
}

uint16_t calcCRC(const uint8_t *data, size_t length)
{
    uint16_t temp = 0xffffu;
    for (size_t i = 0; i < length; ++i) {
        temp ^= data[i];
        for (unsigned int j = 1; j <= 8u; ++j) {
            bool flag = (temp & 1u) != 0u;
            temp >>= 1;
            if (flag) {
                temp ^= 0xa001u;
            }
        }
    }
    /* Upstream's final numeric byte swap is deliberately omitted. */
    return temp;
}

int mb_rtu_frame_length(const uint8_t *data, size_t length, bool response)
{
    if (data == NULL && length != 0u) {
        return -EINVAL;
    }
    if (length < 2u) {
        return 0;
    }
    uint8_t function = data[1];
    if (response && (function & 0x80u) != 0u) {
        return 5;
    }
    if (quantityLimit(function) == 0u) {
        return -ENOTSUP;
    }
    size_t expected = 8;
    if (response && function >= MB_FC_READ_COILS && function <= MB_FC_READ_INPUT_REGISTER) {
        if (length < 3u) {
            return 0;
        }
        expected = 5u + data[2];
    } else if (!response && (function == MB_FC_WRITE_MULTIPLE_COILS ||
                             function == MB_FC_WRITE_MULTIPLE_REGISTERS)) {
        if (length < 7u) {
            return 0;
        }
        expected = 9u + data[6];
    }
    return expected > 256u ? -EMSGSIZE : (int)expected;
}
