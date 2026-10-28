/* SPDX-License-Identifier: LGPL-2.1-only
 * Portable adaptation of Modbus-STM32-HAL-FreeRTOS, Modbus.h / Modbus.c.
 * Original Modbus.h author: Alejandro Mera (2020).
 * Modified for the NV-Migration project, 2026. See ../UPSTREAM.md.
 */
#ifndef MODBUS_CORE_H
#define MODBUS_CORE_H

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef enum MB_FC {
    MB_FC_READ_COILS = 1,
    MB_FC_READ_DISCRETE_INPUT = 2,
    MB_FC_READ_REGISTERS = 3,
    MB_FC_READ_INPUT_REGISTER = 4,
    MB_FC_WRITE_COIL = 5,
    MB_FC_WRITE_REGISTER = 6,
    MB_FC_WRITE_MULTIPLE_COILS = 15,
    MB_FC_WRITE_MULTIPLE_REGISTERS = 16
} mb_functioncode_t;

/* Region sizes are uint16_t words, including bit-packed coil/input regions.
 * A NULL separate-region pointer falls back to u16regs at address zero,
 * ignoring that separate region's size/start. Non-NULL empty regions do not
 * fall back. Addresses in separate bit regions are relative to StartAdd.
 * The caller owns all arrays and serializes access to shared memory.
 */
typedef struct {
    uint16_t *u16regs;
    uint16_t u16regsize;
    uint16_t *u16coils;
    uint16_t u16coilsStartAdd;
    uint16_t u16coilsNregs;
    uint16_t *u16discreteInputs;
    uint16_t u16discreteInputsStartAdd;
    uint16_t u16discreteInputsNregs;
    uint16_t *u16holdingRegs;
    uint16_t u16holdingRegsStartAdd;
    uint16_t u16holdingRegsNregs;
    uint16_t *u16inputRegs;
    uint16_t u16inputRegsStartAdd;
    uint16_t u16inputRegsNregs;
} mb_memory_t;

struct modbus_completion;

typedef struct {
    uint8_t u8id;
    uint8_t u8fct;
    uint8_t u8clientID;
    uint16_t u16RegAdd;
    uint16_t u16CoilsNo;
    uint16_t *u16reg;
    uint16_t u16regCapacity;
    uint16_t u16Port;
    uint32_t xIpAddress; /* Network byte order. */
    struct modbus_completion *completion;
} modbus_t;

/* All PDUs exclude Unit ID, MBAP and CRC. Transport/address filtering and
 * broadcast response suppression belong to the caller. PDU buffers must not
 * overlap a memory bank/query array. Input and output PDU may be identical.
 * No global ADU buffer policy is imposed; capacity is supplied by the caller.
 * Errors use negative errno values. Invalid arguments: EINVAL; insufficient
 * output/data capacity: ENOSPC; malformed responses: EBADMSG; unsupported
 * client function: ENOTSUP. Server malformed requests yield exception 3,
 * invalid ranges exception 2, unsupported functions exception 1.
 */
int mb_core_server(mb_memory_t *map, const uint8_t *pdu, size_t len,
                   uint8_t *reply, size_t capacity);

/* u16CoilsNo must be 1 for FC5/6. u16regCapacity is words; FC1/2/15
 * use bit-packed uint16_t words, least-significant bit first. FC5 follows
 * upstream: zero in u16reg[0] means OFF, any nonzero value means ON.
 * Query data must remain valid and unchanged until response parsing finishes.
 * Build validates both read destination and write source capacity, even though
 * read requests do not read u16reg. Failure leaves the output PDU unchanged.
 */
int mb_core_build(const modbus_t *query, uint8_t *pdu, size_t capacity);

/* Returns 0, a positive exception code, or negative errno. Matching function,
 * exact length, byte count/echo and destination capacity are checked before
 * modifying caller data. Read coils clear unused high bits in the last word.
 * Exception replies must contain exactly two bytes and a nonzero code.
 */
int mb_core_parse(const modbus_t *query, const uint8_t *pdu, size_t len);

/* Conventional CRC16/Modbus numeric result (e.g. "123456789" -> 0x4b37).
 * Append low byte then high byte on wire. Unlike upstream calcCRC, this does
 * NOT swap the numeric result. data may be NULL only when length is zero.
 */
uint16_t calcCRC(const uint8_t *data, size_t length);

/* Expected RTU ADU size, 0 for an insufficient header, -ENOTSUP for unknown
 * FC, -EMSGSIZE for a size over 256, or -EINVAL for NULL nonempty input.
 * This only infers size, not CRC/contents validity. Extra buffered frames do
 * not affect the first frame's inferred size. Exception responses are 5 bytes.
 */
int mb_rtu_frame_length(const uint8_t *data, size_t length, bool response);

#ifdef __cplusplus
}
#endif
#endif
