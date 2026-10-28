/* SPDX-License-Identifier: LGPL-2.1-only
 * NV-Migration portable protocol tests, 2026.
 */
#include "ModbusCore.h"

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static unsigned long checks;
#define CHECK(condition) do { \
    ++checks; \
    if (!(condition)) { \
        fprintf(stderr, "%s:%d: %s\n", __FILE__, __LINE__, #condition); \
        exit(EXIT_FAILURE); \
    } \
} while (0)
#define COUNT(array) (sizeof(array) / sizeof((array)[0]))

static const uint8_t functions[] = {1, 2, 3, 4, 5, 6, 15, 16};
static const uint16_t limits[] = {2000, 2000, 125, 125, 1, 1, 1968, 123};

static void same(const void *actual, const void *expected, size_t length)
{
    CHECK(memcmp(actual, expected, length) == 0);
}

static void be16(uint8_t *out, uint16_t value)
{
    out[0] = (uint8_t)(value / 256u);
    out[1] = (uint8_t)(value % 256u);
}

static modbus_t query(uint8_t function, uint16_t address, uint16_t quantity,
                       uint16_t *data, uint16_t capacity)
{
    modbus_t q = {
        .u8id = 10, .u8fct = function, .u16RegAdd = address,
        .u16CoilsNo = quantity, .u16reg = data, .u16regCapacity = capacity
    };
    return q;
}

/* Independent request fixture encoder; deliberately does not call the core. */
static size_t request(uint8_t *pdu, uint8_t function, uint16_t address, uint16_t quantity)
{
    pdu[0] = function;
    be16(pdu + 1, address);
    be16(pdu + 3, quantity);
    if (function == 15u || function == 16u) {
        size_t bytes = function == 15u ? ((size_t)quantity + 7u) / 8u
                                      : (size_t)quantity * 2u;
        pdu[5] = (uint8_t)bytes;
        memset(pdu + 6, 0x69, bytes);
        return bytes + 6u;
    }
    return 5;
}

static void exception(mb_memory_t *map, const uint8_t *pdu, size_t length, uint8_t code)
{
    uint8_t reply[4] = {0xa5, 0xa5, 0xa5, 0xa5};
    CHECK(mb_core_server(map, pdu, length, reply + 1, 2) == 2);
    CHECK(reply[0] == 0xa5 && reply[3] == 0xa5);
    CHECK(reply[1] == (uint8_t)(pdu[0] | 0x80u) && reply[2] == code);
}

static void golden_server(void)
{
    static const struct {
        uint8_t input[12];
        size_t inputLength;
        uint8_t output[12];
        size_t outputLength;
        uint16_t bank[3];
    } vectors[] = {
        {{1, 0, 0, 0, 19}, 5, {1, 3, 0x5a, 0xa5, 4}, 5,
         {0xa55a, 0xc33c, 0xf00f}},
        {{2, 0, 9, 0, 19}, 5, {2, 3, 0x52, 0x9e, 1}, 5,
         {0xa55a, 0xc33c, 0xf00f}},
        {{3, 0, 1, 0, 2}, 5, {3, 4, 0xc3, 0x3c, 0xf0, 0x0f}, 6,
         {0xa55a, 0xc33c, 0xf00f}},
        {{4, 0, 1, 0, 2}, 5, {4, 4, 0xc3, 0x3c, 0xf0, 0x0f}, 6,
         {0xa55a, 0xc33c, 0xf00f}},
        {{5, 0, 17, 0xff, 0}, 5, {5, 0, 17, 0xff, 0}, 5,
         {0xa55a, 0xc33e, 0xf00f}},
        {{5, 0, 18, 0, 0}, 5, {5, 0, 18, 0, 0}, 5,
         {0xa55a, 0xc338, 0xf00f}},
        {{6, 0, 1, 0x12, 0x34}, 5, {6, 0, 1, 0x12, 0x34}, 5,
         {0xa55a, 0x1234, 0xf00f}},
        {{15, 0, 13, 0, 10, 2, 0xcd, 1}, 8, {15, 0, 13, 0, 10}, 5,
         {0xa55a, 0xc339, 0xf00f}},
        {{16, 0, 1, 0, 2, 4, 0x12, 0x34, 0xab, 0xcd}, 10,
         {16, 0, 1, 0, 2}, 5, {0xa55a, 0x1234, 0xabcd}}
    };
    for (size_t i = 0; i < COUNT(vectors); ++i) {
        for (unsigned int inPlace = 0; inPlace < 2u; ++inPlace) {
            uint16_t bank[] = {0xbeef, 0xa55a, 0xc33c, 0xf00f, 0xcafe};
            mb_memory_t map = {.u16regs = bank + 1, .u16regsize = 3};
            uint8_t reply[16];
            memset(reply, 0xcc, sizeof(reply));
            const uint8_t *input = vectors[i].input;
            if (inPlace != 0u) {
                memcpy(reply + 1, input, vectors[i].inputLength);
                input = reply + 1;
            }
            CHECK(mb_core_server(&map, input, vectors[i].inputLength,
                                 reply + 1, vectors[i].outputLength) == (int)vectors[i].outputLength);
            same(reply + 1, vectors[i].output, vectors[i].outputLength);
            same(bank + 1, vectors[i].bank, sizeof(vectors[i].bank));
            CHECK(bank[0] == 0xbeef && bank[4] == 0xcafe);
            CHECK(reply[0] == 0xcc && reply[15] == 0xcc);
            if (inPlace == 0u) {
                CHECK(reply[vectors[i].outputLength + 1u] == 0xcc);
            }
        }
    }
    uint16_t bank[2] = {0, 0};
    mb_memory_t map = {.u16regs = bank, .u16regsize = 2};
    uint8_t pdu[] = {0x7f};
    exception(&map, pdu, 1, 1);
    pdu[0] = 0;
    exception(&map, pdu, 1, 1);
}

static void golden_client(void)
{
    static const struct {
        uint8_t function;
        uint16_t address, quantity;
        uint16_t initial[2];
        uint8_t request[12];
        size_t requestLength;
        uint8_t response[12];
        size_t responseLength;
        uint16_t expected[2];
    } vectors[] = {
        {1, 0, 19, {0xffff, 0xffff}, {1, 0, 0, 0, 19}, 5,
         {1, 3, 0x5a, 0xa5, 4}, 5, {0xa55a, 4}},
        {2, 9, 19, {0xffff, 0xffff}, {2, 0, 9, 0, 19}, 5,
         {2, 3, 0x52, 0x9e, 1}, 5, {0x9e52, 1}},
        {3, 1, 2, {0, 0}, {3, 0, 1, 0, 2}, 5,
         {3, 4, 0xc3, 0x3c, 0xf0, 0x0f}, 6, {0xc33c, 0xf00f}},
        {4, 1, 2, {0, 0}, {4, 0, 1, 0, 2}, 5,
         {4, 4, 0xc3, 0x3c, 0xf0, 0x0f}, 6, {0xc33c, 0xf00f}},
        {5, 17, 1, {1, 0}, {5, 0, 17, 0xff, 0}, 5,
         {5, 0, 17, 0xff, 0}, 5, {1, 0}},
        {5, 18, 1, {0, 0}, {5, 0, 18, 0, 0}, 5,
         {5, 0, 18, 0, 0}, 5, {0, 0}},
        {5, 17, 1, {0x1234, 0}, {5, 0, 17, 0xff, 0}, 5,
         {5, 0, 17, 0xff, 0}, 5, {0x1234, 0}},
        {6, 1, 1, {0xabcd, 0}, {6, 0, 1, 0xab, 0xcd}, 5,
         {6, 0, 1, 0xab, 0xcd}, 5, {0xabcd, 0}},
        {15, 13, 10, {0xfdcd, 0}, {15, 0, 13, 0, 10, 2, 0xcd, 1}, 8,
         {15, 0, 13, 0, 10}, 5, {0xfdcd, 0}},
        {16, 1, 2, {0x1234, 0xabcd}, {16, 0, 1, 0, 2, 4, 0x12, 0x34, 0xab, 0xcd}, 10,
         {16, 0, 1, 0, 2}, 5, {0x1234, 0xabcd}}
    };
    for (size_t i = 0; i < COUNT(vectors); ++i) {
        uint16_t data[] = {0xbeef, vectors[i].initial[0], vectors[i].initial[1], 0xcafe};
        modbus_t q = query(vectors[i].function, vectors[i].address,
                           vectors[i].quantity, data + 1, 2);
        uint8_t pdu[16];
        memset(pdu, 0xa5, sizeof(pdu));
        CHECK(mb_core_build(&q, pdu + 1, vectors[i].requestLength) == (int)vectors[i].requestLength);
        same(pdu + 1, vectors[i].request, vectors[i].requestLength);
        CHECK(pdu[0] == 0xa5 && pdu[vectors[i].requestLength + 1u] == 0xa5);
        same(data + 1, vectors[i].initial, sizeof(vectors[i].initial));
        CHECK(mb_core_parse(&q, vectors[i].response, vectors[i].responseLength) == 0);
        same(data + 1, vectors[i].expected, sizeof(vectors[i].expected));
        CHECK(data[0] == 0xbeef && data[3] == 0xcafe);
    }
    /* Excess server padding bits cannot leak into the caller's packed word. */
    uint16_t data[] = {0xffff, 0xcafe};
    modbus_t q = query(1, 0, 1, data, 1);
    const uint8_t padded[] = {1, 1, 0xff};
    CHECK(mb_core_parse(&q, padded, sizeof(padded)) == 0);
    CHECK(data[0] == 1 && data[1] == 0xcafe);
}

static void maps(void)
{
    uint16_t shared[] = {0xaaaa, 0x5555};
    uint16_t coils[] = {0x1234, 0xabcd};
    uint16_t di[] = {0x9876, 0x4567};
    uint16_t hr[] = {0xdead, 0xbeef};
    uint16_t ir[] = {0x1357, 0x2468};
    mb_memory_t map = {
        .u16regs = shared, .u16regsize = 2,
        .u16coils = coils, .u16coilsStartAdd = 3, .u16coilsNregs = 2,
        .u16discreteInputs = di, .u16discreteInputsStartAdd = 100, .u16discreteInputsNregs = 2,
        .u16holdingRegs = hr, .u16holdingRegsStartAdd = 200, .u16holdingRegsNregs = 2,
        .u16inputRegs = ir, .u16inputRegsStartAdd = 300, .u16inputRegsNregs = 2
    };
    uint8_t pdu[16], reply[16];
    const uint16_t starts[] = {3, 100, 200, 300};
    const uint16_t first[] = {0x1234, 0x9876, 0xdead, 0x1357};
    const uint16_t last[] = {1, 0, 0xbeef, 0x2468};
    for (uint8_t f = 1; f <= 4; ++f) {
        uint16_t n = f <= 2u ? 16 : 1;
        (void)request(pdu, f, starts[f - 1u], n);
        CHECK(mb_core_server(&map, pdu, 5, reply, sizeof(reply)) == 4);
        CHECK(reply[0] == f && reply[1] == 2);
        uint16_t decoded = f <= 2u ? (uint16_t)((uint16_t)reply[3] * 256u + reply[2])
                                   : (uint16_t)((uint16_t)reply[2] * 256u + reply[3]);
        CHECK(decoded == first[f - 1u]);
        uint16_t address = (uint16_t)(starts[f - 1u] + (f <= 2u ? 31u : 1u));
        (void)request(pdu, f, address, 1);
        CHECK(mb_core_server(&map, pdu, 5, reply, sizeof(reply)) == (f <= 2u ? 3 : 4));
        decoded = f <= 2u ? reply[2] : (uint16_t)((uint16_t)reply[2] * 256u + reply[3]);
        CHECK(decoded == last[f - 1u]);
        (void)request(pdu, f, (uint16_t)(starts[f - 1u] - 1u), 1);
        exception(&map, pdu, 5, 2);
        (void)request(pdu, f, (uint16_t)(address + 1u), 1);
        exception(&map, pdu, 5, 2);
        (void)request(pdu, f, address, 2);
        exception(&map, pdu, 5, 2);
    }
    (void)request(pdu, 5, 3, 0xff00);
    CHECK(mb_core_server(&map, pdu, 5, reply, sizeof(reply)) == 5);
    CHECK(coils[0] == 0x1235 && di[0] == 0x9876 && shared[0] == 0xaaaa);
    (void)request(pdu, 6, 201, 0x8888);
    CHECK(mb_core_server(&map, pdu, 5, reply, sizeof(reply)) == 5);
    CHECK(hr[1] == 0x8888 && ir[1] == 0x2468 && shared[1] == 0x5555);
    size_t length = request(pdu, 15, 18, 2);
    pdu[6] = 1;
    CHECK(mb_core_server(&map, pdu, length, reply, sizeof(reply)) == 5);
    CHECK(coils[0] == 0x9235 && coils[1] == 0xabcc);
    length = request(pdu, 16, 200, 2);
    CHECK(mb_core_server(&map, pdu, length, reply, sizeof(reply)) == 5);
    CHECK(hr[0] == 0x6969 && hr[1] == 0x6969 && ir[0] == 0x1357);

    /* Fallback is independent for each type, ignoring its stale metadata. */
    for (uint8_t f = 1; f <= 4; ++f) {
        mb_memory_t fallback = map;
        if (f == 1u) fallback.u16coils = NULL;
        if (f == 2u) fallback.u16discreteInputs = NULL;
        if (f == 3u) fallback.u16holdingRegs = NULL;
        if (f == 4u) fallback.u16inputRegs = NULL;
        (void)request(pdu, f, 0, f <= 2u ? 16 : 1);
        CHECK(mb_core_server(&fallback, pdu, 5, reply, sizeof(reply)) == 4);
        CHECK(reply[2] == 0xaa && reply[3] == 0xaa);
        fallback.u16regs = NULL;
        exception(&fallback, pdu, 5, 2);
    }
    map.u16coilsNregs = 0;
    (void)request(pdu, 1, 3, 1);
    exception(&map, pdu, 5, 2);
    map.u16holdingRegsNregs = 0;
    (void)request(pdu, 6, 200, 0x1234);
    exception(&map, pdu, 5, 2);

    mb_memory_t legacy = {.u16regs = shared, .u16regsize = 2};
    (void)request(pdu, 6, 0, 0x8001);
    CHECK(mb_core_server(&legacy, pdu, 5, reply, sizeof(reply)) == 5);
    for (uint8_t f = 1; f <= 4; ++f) {
        (void)request(pdu, f, 0, f <= 2u ? 16 : 1);
        CHECK(mb_core_server(&legacy, pdu, 5, reply, sizeof(reply)) == 4);
        CHECK(reply[2] == (f <= 2u ? 1 : 0x80));
        CHECK(reply[3] == (f <= 2u ? 0x80 : 1));
    }
    (void)request(pdu, 5, 0, 0);
    CHECK(mb_core_server(&legacy, pdu, 5, reply, sizeof(reply)) == 5);
    CHECK(shared[0] == 0x8000);
}

static void server_bounds(void)
{
    uint16_t bank[4096];
    memset(bank, 0xa5, sizeof(bank));
    uint16_t snapshot[4096];
    memcpy(snapshot, bank, sizeof(bank));
    mb_memory_t map = {.u16regs = bank, .u16regsize = 4096};
    uint8_t pdu[512], reply[260];
    CHECK(mb_core_server(NULL, pdu, 0, reply, sizeof(reply)) == -EINVAL);
    CHECK(mb_core_server(&map, NULL, 1, reply, sizeof(reply)) == -EINVAL);
    CHECK(mb_core_server(&map, pdu, 0, reply, sizeof(reply)) == -EINVAL);
    CHECK(mb_core_server(&map, pdu, 1, NULL, 0) == -EINVAL);
    for (size_t f = 0; f < COUNT(functions); ++f) {
        uint8_t fc = functions[f];
        bool bits = fc == 1u || fc == 2u || fc == 5u || fc == 15u;
        uint16_t quantity = limits[f];
        size_t length = request(pdu, fc, 0, fc == 5u ? 0xff00u : quantity);
        int expected = fc <= 4u ? 2 + (bits ? (quantity + 7) / 8 : quantity * 2) : 5;
        for (size_t capacity = 0; capacity < (size_t)expected; ++capacity) {
            memset(reply, 0xcc, sizeof(reply));
            CHECK(mb_core_server(&map, pdu, length, reply, capacity) == -ENOSPC);
            same(bank, snapshot, sizeof(bank));
            for (size_t i = 0; i < sizeof(reply); ++i) CHECK(reply[i] == 0xcc);
        }
        CHECK(mb_core_server(&map, pdu, length, reply, (size_t)expected) == expected);
        memcpy(bank, snapshot, sizeof(bank));
        if (fc != 5u && fc != 6u) {
            length = request(pdu, fc, 0, 0);
            exception(&map, pdu, length, 3);
            length = request(pdu, fc, 0, (uint16_t)(limits[f] + 1u));
            exception(&map, pdu, length, 3);
            be16(pdu + 3, 0xffff);
            exception(&map, pdu, length, 3);
        }
        /* Exact end, one past bank, and a request crossing its end. */
        map.u16regsize = 2;
        uint16_t last = bits ? 31 : 1;
        length = request(pdu, fc, last, 1);
        if (fc == 5u) be16(pdu + 3, 0xff00);
        CHECK(mb_core_server(&map, pdu, length, reply, sizeof(reply)) > 2);
        memcpy(bank, snapshot, sizeof(bank));
        be16(pdu + 1, (uint16_t)(last + 1u));
        exception(&map, pdu, length, 2);
        if (fc != 5u && fc != 6u) {
            length = request(pdu, fc, last, 2);
            exception(&map, pdu, length, 2);
        }
        same(bank, snapshot, sizeof(bank));
        map.u16regsize = 4096;
    }
    /* Legal last protocol address, then reject wrap even if the bank fits. */
    map.u16holdingRegs = bank;
    map.u16holdingRegsStartAdd = 65530;
    map.u16holdingRegsNregs = 20;
    map.u16inputRegs = bank;
    map.u16inputRegsStartAdd = 65530;
    map.u16inputRegsNregs = 20;
    map.u16coils = bank;
    map.u16coilsStartAdd = 65530;
    map.u16coilsNregs = 20;
    map.u16discreteInputs = bank;
    map.u16discreteInputsStartAdd = 65530;
    map.u16discreteInputsNregs = 20;
    for (size_t f = 0; f < COUNT(functions); ++f) {
        uint8_t fc = functions[f];
        size_t length = request(pdu, fc, 65535, fc == 5u ? 0xff00u : 1u);
        CHECK(mb_core_server(&map, pdu, length, reply, sizeof(reply)) > 2);
        if (fc != 5u && fc != 6u) {
            length = request(pdu, fc, 65535, 2);
            exception(&map, pdu, length, 2);
        }
        length = request(pdu, fc, 65529, fc == 5u ? 0xff00u : 1u);
        exception(&map, pdu, length, 2);
    }
    map = (mb_memory_t){.u16regs = bank, .u16regsize = 4096};
    /* The transport's 128-byte ADU default leaves 125 PDU bytes. */
    (void)request(pdu, 3, 0, 61);
    CHECK(mb_core_server(&map, pdu, 5, reply, 125) == 124);
    (void)request(pdu, 3, 0, 62);
    CHECK(mb_core_server(&map, pdu, 5, reply, 125) == -ENOSPC);
    CHECK(mb_core_server(&map, pdu, 5, reply, 253) == 126);
    (void)request(pdu, 1, 0, 984);
    CHECK(mb_core_server(&map, pdu, 5, reply, 125) == 125);
    (void)request(pdu, 1, 0, 985);
    CHECK(mb_core_server(&map, pdu, 5, reply, 125) == -ENOSPC);
    CHECK(mb_core_server(&map, pdu, 5, reply, 253) == 126);
    pdu[0] = 99;
    memset(reply, 0x55, sizeof(reply));
    CHECK(mb_core_server(&map, pdu, 1, reply, 1) == -ENOSPC);
    CHECK(reply[0] == 0x55 && reply[1] == 0x55);
}

static void client_validation(void)
{
    uint16_t data[126];
    memset(data, 0xa5, sizeof(data));
    uint16_t snapshot[126];
    memcpy(snapshot, data, sizeof(data));
    uint8_t pdu[260], built[260];
    CHECK(mb_core_build(NULL, built, sizeof(built)) == -EINVAL);
    CHECK(mb_core_parse(NULL, pdu, 0) == -EINVAL);
    for (size_t f = 0; f < COUNT(functions); ++f) {
        uint8_t fc = functions[f];
        bool bits = fc == 1u || fc == 2u || fc == 5u || fc == 15u;
        uint16_t n = limits[f];
        uint16_t words = bits ? (uint16_t)((n + 15u) / 16u) : n;
        modbus_t q = query(fc, 0, n, data, words);
        int length = mb_core_build(&q, built, sizeof(built));
        CHECK(length > 0);
        same(data, snapshot, sizeof(data));
        for (size_t capacity = 0; capacity < (size_t)length; ++capacity) {
            memset(pdu, 0xcc, sizeof(pdu));
            CHECK(mb_core_build(&q, pdu, capacity) == -ENOSPC);
            for (size_t i = 0; i < sizeof(pdu); ++i) CHECK(pdu[i] == 0xcc);
        }
        for (uint16_t capacity = 0; capacity < words; ++capacity) {
            q.u16regCapacity = capacity;
            CHECK(mb_core_build(&q, pdu, sizeof(pdu)) == -ENOSPC);
            CHECK(mb_core_parse(&q, built, (size_t)length) == -ENOSPC);
            same(data, snapshot, sizeof(data));
        }
        q.u16regCapacity = words;
        q.u16CoilsNo = 0;
        CHECK(mb_core_build(&q, pdu, sizeof(pdu)) == -EINVAL);
        q.u16CoilsNo = (uint16_t)(n + 1u);
        CHECK(mb_core_build(&q, pdu, sizeof(pdu)) == -EINVAL);
        q.u16CoilsNo = n;
        q.u16reg = NULL;
        CHECK(mb_core_build(&q, pdu, sizeof(pdu)) == -EINVAL);
        q.u16reg = data;
        CHECK(mb_core_build(&q, NULL, 0) == -EINVAL);
        CHECK(mb_core_parse(&q, NULL, 0) == -EINVAL);
        q.u16RegAdd = 65535;
        CHECK(mb_core_build(&q, pdu, sizeof(pdu)) == (n > 1u ? -EINVAL : 5));

        q = query(fc, 0x1234, fc == 5u || fc == 6u ? 1 : 17, data, 126);
        length = mb_core_build(&q, built, sizeof(built));
        CHECK(length >= 5);
        size_t responseLength;
        if (fc <= 4u) {
            size_t bytes = fc <= 2u ? 3u : 34u;
            pdu[0] = fc;
            pdu[1] = (uint8_t)bytes;
            memset(pdu + 2, 0x69, bytes);
            responseLength = 2u + bytes;
        } else {
            memcpy(pdu, built, 5);
            responseLength = 5;
        }
        /* Every truncated prefix and an extra byte must leave data intact. */
        for (size_t len = 0; len < responseLength; ++len) {
            uint8_t *exact = malloc(len == 0u ? 1u : len);
            CHECK(exact != NULL);
            memcpy(exact, pdu, len);
            CHECK(mb_core_parse(&q, exact, len) == -EBADMSG);
            same(data, snapshot, sizeof(data));
            free(exact);
        }
        pdu[responseLength] = 0;
        CHECK(mb_core_parse(&q, pdu, responseLength + 1u) == -EBADMSG);
        for (size_t wrong = 0; wrong < COUNT(functions); ++wrong) {
            if (functions[wrong] == fc) continue;
            pdu[0] = functions[wrong];
            CHECK(mb_core_parse(&q, pdu, responseLength) == -EBADMSG);
        }
        pdu[0] = fc;
        if (fc <= 4u) {
            uint8_t count = pdu[1];
            for (unsigned int bad = 0; bad <= 255u; ++bad) {
                if (bad == count) continue;
                pdu[1] = (uint8_t)bad;
                CHECK(mb_core_parse(&q, pdu, responseLength) == -EBADMSG);
                same(data, snapshot, sizeof(data));
            }
            pdu[1] = count;
        } else {
            for (size_t byte = 1; byte < 5u; ++byte) {
                pdu[byte] ^= 1;
                CHECK(mb_core_parse(&q, pdu, responseLength) == -EBADMSG);
                pdu[byte] ^= 1;
                same(data, snapshot, sizeof(data));
            }
        }
        CHECK(mb_core_parse(&q, pdu, responseLength) == 0);
        memcpy(data, snapshot, sizeof(data));
        uint8_t error[] = {(uint8_t)(fc | 0x80u), 2, 0};
        for (unsigned int code = 1; code <= 255u; ++code) {
            error[1] = (uint8_t)code;
            CHECK(mb_core_parse(&q, error, 2) == (int)code);
            same(data, snapshot, sizeof(data));
        }
        error[1] = 0;
        CHECK(mb_core_parse(&q, error, 2) == -EBADMSG);
        error[1] = 2;
        CHECK(mb_core_parse(&q, error, 1) == -EBADMSG);
        CHECK(mb_core_parse(&q, error, 3) == -EBADMSG);
        error[0] = (uint8_t)((fc == 1u ? 2u : 1u) | 0x80u);
        CHECK(mb_core_parse(&q, error, 2) == -EBADMSG);
    }
    modbus_t q = query(0x7f, 0, 1, data, 126);
    CHECK(mb_core_build(&q, pdu, sizeof(pdu)) == -ENOTSUP);
    CHECK(mb_core_parse(&q, pdu, 0) == -ENOTSUP);
    /* A one-past pointer is never dereferenced when a capacity check fails. */
    uint16_t *small = malloc(sizeof(*small));
    CHECK(small != NULL);
    q = query(16, 0, 2, small + 1, 0);
    CHECK(mb_core_build(&q, pdu, sizeof(pdu)) == -ENOSPC);
    q.u16regCapacity = 2;
    CHECK(mb_core_build(&q, pdu, 0) == -ENOSPC);
    free(small);
    q = query(16, 0, 59, data, 126);
    CHECK(mb_core_build(&q, pdu, 125) == 124);
    q.u16CoilsNo = 60;
    CHECK(mb_core_build(&q, pdu, 125) == -ENOSPC);
    CHECK(mb_core_build(&q, pdu, 253) == 126);
    q = query(15, 0, 952, data, 126);
    CHECK(mb_core_build(&q, pdu, 125) == 125);
    q.u16CoilsNo = 953;
    CHECK(mb_core_build(&q, pdu, 125) == -ENOSPC);
    CHECK(mb_core_build(&q, pdu, 253) == 126);
}

static void crc(void)
{
    static const uint8_t ascii[] = "123456789";
    static const uint8_t readTen[] = {1, 3, 0, 0, 0, 10};
    static const uint8_t adu[] = {1, 3, 0, 0, 0, 10, 0xc5, 0xcd};
    CHECK(calcCRC(NULL, 0) == 0xffff);
    CHECK(calcCRC(ascii, sizeof(ascii) - 1u) == 0x4b37);
    CHECK(calcCRC(readTen, sizeof(readTen)) == 0xcdc5);
    CHECK(calcCRC(adu, sizeof(adu)) == 0);
    for (size_t bit = 0; bit < sizeof(adu) * 8u; ++bit) {
        uint8_t corrupt[sizeof(adu)];
        memcpy(corrupt, adu, sizeof(adu));
        corrupt[bit / 8u] ^= (uint8_t)(1u << (bit % 8u));
        CHECK(calcCRC(corrupt, sizeof(corrupt)) != 0);
    }
    /* Lengths no longer wrap at the upstream uint8_t boundary. */
    uint8_t longData[1026];
    for (size_t i = 0; i < 1024u; ++i) longData[i] = (uint8_t)i;
    uint16_t result = calcCRC(longData, 1024);
    longData[1024] = (uint8_t)result;
    longData[1025] = (uint8_t)(result >> 8);
    CHECK(calcCRC(longData, sizeof(longData)) == 0);
}

static void rtu_lengths(void)
{
    CHECK(mb_rtu_frame_length(NULL, 0, false) == 0);
    CHECK(mb_rtu_frame_length(NULL, 1, false) == -EINVAL);
    for (unsigned int response = 0; response < 2u; ++response) {
        for (unsigned int function = 0; function <= 255u; ++function) {
            for (size_t length = 0; length <= 8u; ++length) {
                uint8_t *data = malloc(length == 0u ? 1u : length);
                CHECK(data != NULL);
                memset(data, 0, length);
                if (length > 0u) data[0] = 1;
                if (length > 1u) data[1] = (uint8_t)function;
                if (length > 2u) data[2] = 4;
                if (length > 6u) data[6] = 4;
                int expected;
                if (length < 2u) expected = 0;
                else if (response != 0u && function >= 128u) expected = 5;
                else if (function == 0u || (function > 6u && function != 15u && function != 16u)) expected = -ENOTSUP;
                else if (response != 0u && function <= 4u) expected = length < 3u ? 0 : 9;
                else if (response == 0u && (function == 15u || function == 16u)) expected = length < 7u ? 0 : 13;
                else expected = 8;
                CHECK(mb_rtu_frame_length(data, length, response != 0u) == expected);
                free(data);
            }
        }
    }
    uint8_t data[520] = {1, 3};
    for (unsigned int count = 0; count <= 255u; ++count) {
        data[2] = (uint8_t)count;
        CHECK(mb_rtu_frame_length(data, sizeof(data), true) ==
              (count <= 251u ? (int)(count + 5u) : -EMSGSIZE));
        data[1] = 15;
        data[6] = (uint8_t)count;
        CHECK(mb_rtu_frame_length(data, sizeof(data), false) ==
              (count <= 247u ? (int)(count + 9u) : -EMSGSIZE));
        data[1] = 16;
        CHECK(mb_rtu_frame_length(data, sizeof(data), false) ==
              (count <= 247u ? (int)(count + 9u) : -EMSGSIZE));
        data[1] = 3;
    }
    static const uint8_t stream[] = {1, 3, 0, 0, 0, 10, 0xc5, 0xcd, 1, 6, 0, 1, 0, 2, 0x59, 0xcb};
    CHECK(mb_rtu_frame_length(stream, sizeof(stream), false) == 8);
    CHECK(mb_rtu_frame_length(stream + 8, sizeof(stream) - 8u, false) == 8);
}

static void exhaustive_bits(void)
{
    const uint16_t initial[] = {0x935a, 0x8fc1, 0x247e, 0xb60d};
    for (uint16_t start = 0; start < 64u; ++start) {
        for (uint16_t count = 1; count <= 64u - start; ++count) {
            uint16_t bank[6] = {0xbeef, 0, 0, 0, 0, 0xcafe};
            memcpy(bank + 1, initial, sizeof(initial));
            mb_memory_t map = {.u16regs = bank + 1, .u16regsize = 4};
            uint8_t input[16], reply[16], expected[16] = {1};
            size_t bytes = (count + 7u) / 8u;
            expected[1] = (uint8_t)bytes;
            for (uint16_t i = 0; i < count; ++i) {
                unsigned int absolute = start + i;
                if ((initial[absolute / 16u] & (1u << (absolute % 16u))) != 0u) {
                    expected[2u + i / 8u] |= (uint8_t)(1u << (i % 8u));
                }
            }
            (void)request(input, 1, start, count);
            CHECK(mb_core_server(&map, input, 5, reply, sizeof(reply)) == (int)(bytes + 2u));
            same(reply, expected, bytes + 2u);
            uint16_t destination[6] = {0xdead, 0xffff, 0xffff, 0xffff, 0xffff, 0xabcd};
            modbus_t q = query(1, start, count, destination + 1, (uint16_t)((count + 15u) / 16u));
            CHECK(mb_core_parse(&q, reply, bytes + 2u) == 0);
            for (unsigned int i = 0; i < 64u; ++i) {
                bool actual = (destination[1u + i / 16u] & (1u << (i % 16u))) != 0u;
                bool wanted = i < count
                    ? (initial[(start + i) / 16u] & (1u << ((start + i) % 16u))) != 0u
                    : (i >= ((unsigned int)count + 15u) / 16u * 16u);
                CHECK(actual == wanted);
            }
            CHECK(destination[0] == 0xdead && destination[5] == 0xabcd);
            size_t length = request(input, 15, start, count);
            for (size_t i = 0; i < bytes; ++i) input[6u + i] = (uint8_t)(0xd3u + i);
            CHECK(mb_core_server(&map, input, length, reply, sizeof(reply)) == 5);
            for (unsigned int i = 0; i < 64u; ++i) {
                bool actual = (bank[1u + i / 16u] & (1u << (i % 16u))) != 0u;
                bool wanted = i >= start && i < (unsigned int)start + count
                    ? (input[6u + (i - start) / 8u] & (1u << ((i - start) % 8u))) != 0u
                    : (initial[i / 16u] & (1u << (i % 16u))) != 0u;
                CHECK(actual == wanted);
            }
            CHECK(bank[0] == 0xbeef && bank[5] == 0xcafe);
        }
    }
}

static uint32_t randomState = 0x9c022fd2u;
static uint32_t next_random(void)
{
    randomState ^= randomState << 13;
    randomState ^= randomState >> 17;
    randomState ^= randomState << 5;
    return randomState;
}

static void randomized(void)
{
    uint16_t bank[130], expected[130], data[127];
    uint8_t input[256], reply[256];
    for (unsigned int iteration = 0; iteration < 12000u; ++iteration) {
        for (size_t i = 0; i < COUNT(bank); ++i) bank[i] = (uint16_t)next_random();
        memcpy(expected, bank, sizeof(bank));
        for (size_t i = 0; i < COUNT(data); ++i) data[i] = (uint16_t)next_random();
        size_t f = iteration % COUNT(functions);
        uint8_t fc = functions[f];
        bool bits = fc == 1u || fc == 2u || fc == 5u || fc == 15u;
        uint16_t count = (uint16_t)(1u + next_random() % limits[f]);
        uint16_t maxAddress = bits ? 2048 : 128;
        uint16_t address = (uint16_t)(next_random() % (uint32_t)(maxAddress - count + 1u));
        uint16_t offset = (uint16_t)(next_random() % 63000u);
        mb_memory_t map = {
            .u16coils = bank + 1, .u16coilsNregs = 128, .u16coilsStartAdd = offset,
            .u16discreteInputs = bank + 1, .u16discreteInputsNregs = 128, .u16discreteInputsStartAdd = offset,
            .u16holdingRegs = bank + 1, .u16holdingRegsNregs = 128, .u16holdingRegsStartAdd = offset,
            .u16inputRegs = bank + 1, .u16inputRegsNregs = 128, .u16inputRegsStartAdd = offset
        };
        modbus_t q = query(fc, (uint16_t)(address + offset), count, data + 1, 125);
        int inputLength = mb_core_build(&q, input, sizeof(input));
        CHECK(inputLength > 0 && inputLength <= 253);
        uint16_t before = data[0], after = data[126];
        if (fc == 5u) {
            unsigned int bit = address % 16u;
            uint16_t mask = (uint16_t)(1u << bit);
            if (data[1] != 0u) expected[1u + address / 16u] |= mask;
            else expected[1u + address / 16u] &= (uint16_t)~mask;
        } else if (fc == 15u) {
            for (unsigned int i = 0; i < count; ++i) {
                uint16_t mask = (uint16_t)(1u << ((address + i) % 16u));
                if ((data[1u + i / 16u] & (1u << (i % 16u))) != 0u)
                    expected[1u + (address + i) / 16u] |= mask;
                else expected[1u + (address + i) / 16u] &= (uint16_t)~mask;
            }
        } else if (fc == 6u || fc == 16u) {
            memcpy(expected + 1u + address, data + 1, (size_t)count * sizeof(*data));
        }
        int replyLength = mb_core_server(&map, input, (size_t)inputLength, reply, sizeof(reply));
        CHECK(replyLength > 2 && replyLength <= 253);
        same(bank, expected, sizeof(bank));
        CHECK(mb_core_parse(&q, reply, (size_t)replyLength) == 0);
        if (fc <= 2u) {
            for (unsigned int i = 0; i < count; ++i) {
                CHECK(((data[1u + i / 16u] >> (i % 16u)) & 1u) ==
                      ((bank[1u + (address + i) / 16u] >> ((address + i) % 16u)) & 1u));
            }
        } else if (fc <= 4u) {
            same(data + 1, bank + 1u + address, (size_t)count * sizeof(*data));
        }
        CHECK(data[0] == before && data[126] == after);
    }
}

static void malformed(void)
{
    uint16_t bank[128], snapshot[128];
    memset(bank, 0x96, sizeof(bank));
    memcpy(snapshot, bank, sizeof(bank));
    mb_memory_t map = {.u16regs = bank, .u16regsize = 128};
    uint8_t pdu[260], reply[260];
    /* Exhaust every invalid FC5 value, not just its high byte. */
    for (uint32_t value = 0; value <= 65535u; ++value) {
        if (value == 0u || value == 0xff00u) continue;
        (void)request(pdu, 5, 0, (uint16_t)value);
        exception(&map, pdu, 5, 3);
        same(bank, snapshot, sizeof(bank));
    }
    for (size_t f = 0; f < COUNT(functions); ++f) {
        uint8_t fc = functions[f];
        size_t length = request(pdu, fc, 0, fc == 5u ? 0xff00u : (fc == 6u ? 1u : 17u));
        for (size_t len = 1; len < length; ++len) {
            uint8_t *exact = malloc(len);
            CHECK(exact != NULL);
            memcpy(exact, pdu, len);
            exception(&map, exact, len, 3);
            same(bank, snapshot, sizeof(bank));
            free(exact);
        }
        pdu[length] = 0;
        exception(&map, pdu, length + 1u, 3);
        same(bank, snapshot, sizeof(bank));
        if (fc == 15u || fc == 16u) {
            uint8_t count = pdu[5];
            for (unsigned int bad = 0; bad <= 255u; ++bad) {
                if (bad == count) continue;
                pdu[5] = (uint8_t)bad;
                exception(&map, pdu, length, 3);
                same(bank, snapshot, sizeof(bank));
            }
        }
    }
    /* Deterministic malformed byte streams with exact-size allocations under
     * ASAN. Any exception/negative status must preserve the entire data bank. */
    for (unsigned int iteration = 0; iteration < 24000u; ++iteration) {
        size_t length = next_random() % 261u;
        uint8_t *exact = malloc(length == 0u ? 1u : length);
        CHECK(exact != NULL);
        for (size_t i = 0; i < length; ++i) exact[i] = (uint8_t)next_random();
        if (length != 0u && iteration % 2u == 0u) exact[0] = functions[iteration % COUNT(functions)];
        size_t capacity = next_random() % 260u;
        uint8_t *out = malloc(capacity == 0u ? 1u : capacity);
        CHECK(out != NULL);
        int result = mb_core_server(&map, exact, length, out, capacity);
        CHECK(result < 0 || (size_t)result <= capacity);
        if (result <= 2) same(bank, snapshot, sizeof(bank));
        memcpy(bank, snapshot, sizeof(bank));
        uint16_t data[127], saved[127];
        memset(data, 0x69, sizeof(data));
        memcpy(saved, data, sizeof(data));
        uint8_t fc = functions[iteration % COUNT(functions)];
        modbus_t q = query(fc, 0, fc == 5u || fc == 6u ? 1 : 17, data + 1, 125);
        result = mb_core_parse(&q, exact, length);
        if (result != 0) same(data, saved, sizeof(data));
        CHECK(data[0] == saved[0] && data[126] == saved[126]);
        (void)mb_rtu_frame_length(exact, length, false);
        (void)mb_rtu_frame_length(exact, length, true);
        free(out);
        free(exact);
    }
    CHECK(mb_core_server(&map, pdu, 0, reply, sizeof(reply)) == -EINVAL);
}

int main(int argc, char **argv)
{
    static const struct { const char *name; void (*run)(void); } suites[] = {
        {"golden_server", golden_server}, {"golden_client", golden_client},
        {"maps", maps}, {"server_bounds", server_bounds},
        {"client_validation", client_validation}, {"crc", crc},
        {"rtu_lengths", rtu_lengths}, {"exhaustive_bits", exhaustive_bits},
        {"randomized", randomized}, {"malformed", malformed}
    };
    if (argc != 2) {
        fprintf(stderr, "usage: %s <suite>\n", argv[0]);
        return EXIT_FAILURE;
    }
    for (size_t i = 0; i < COUNT(suites); ++i) {
        if (strcmp(argv[1], suites[i].name) == 0) {
            suites[i].run();
            printf("%s: PASS (%lu checks)\n", suites[i].name, checks);
            return EXIT_SUCCESS;
        }
    }
    fprintf(stderr, "unknown suite: %s\n", argv[1]);
    return EXIT_FAILURE;
}
