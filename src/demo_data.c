/* SPDX-License-Identifier: Apache-2.0 */
#include "app.h"
#include <string.h>

static struct {
    uint16_t shared[IS_ENABLED(CONFIG_APP_LARGE_TEST_MAP) ? 128 : 16];
    uint16_t coils[2];
    uint16_t inputs[2];
    uint16_t holding[4];
    uint16_t registers[4];
} banks[2];

void app_data_init(mb_memory_t *memory, unsigned int bank)
{
    __ASSERT_NO_MSG(bank < ARRAY_SIZE(banks));
    memset(memory, 0, sizeof(*memory));
    if (IS_ENABLED(CONFIG_APP_SEPARATE_REGIONS)) {
        memory->u16coils = banks[bank].coils;
        memory->u16coilsStartAdd = 0;
        memory->u16coilsNregs = 2;
        memory->u16discreteInputs = banks[bank].inputs;
        memory->u16discreteInputsStartAdd = 100;
        memory->u16discreteInputsNregs = 2;
        memory->u16holdingRegs = banks[bank].holding;
        memory->u16holdingRegsStartAdd = 200;
        memory->u16holdingRegsNregs = 4;
        memory->u16inputRegs = banks[bank].registers;
        memory->u16inputRegsStartAdd = 300;
        memory->u16inputRegsNregs = 4;
    } else {
        memory->u16regs = banks[bank].shared;
        memory->u16regsize = ARRAY_SIZE(banks[bank].shared);
    }
}

uint16_t app_data_address(uint8_t function)
{
    if (!IS_ENABLED(CONFIG_APP_SEPARATE_REGIONS)) {
        return 0;
    }
    switch (function) {
    case 2: return 100;
    case 3:
    case 6:
    case 16: return 200;
    case 4: return 300;
    default: return 0;
    }
}
