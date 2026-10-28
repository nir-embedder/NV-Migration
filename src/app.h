/* SPDX-License-Identifier: Apache-2.0 */
#ifndef NV_MODBUS_APP_H
#define NV_MODBUS_APP_H
#include "Modbus.h"

int app_usb_init(void);
int app_network_init(void);
void app_transport_reset(bool reset_network);
void app_data_init(mb_memory_t *memory, unsigned int bank);
uint16_t app_data_address(uint8_t function);
#endif
