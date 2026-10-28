/* SPDX-License-Identifier: LGPL-2.1-only
 * Modified 2026-10-28 for NV-Migration: Kconfig-backed transport capacities.
 */
#ifndef MODBUS_PORT_CONFIG_H
#define MODBUS_PORT_CONFIG_H

/* Upstream ModbusConfigTemplate.h at 9c022fd2538edb5b53e2e07c98ebbe9a4685546c:
 * 128-byte ADU, two queued telegrams and four TCP connections.
 */
#define MB_BUFFER_SIZE CONFIG_MODBUS_PORT_BUFFER_SIZE
/* Replace RTU's three transport bytes with TCP's seven-byte MBAP/unit header. */
#define MB_TCP_BUFFER_SIZE (MB_BUFFER_SIZE + 4U)
#define MB_QUEUE_DEPTH CONFIG_MODBUS_PORT_QUEUE_DEPTH
#define MB_TCP_CONNECTIONS CONFIG_MODBUS_PORT_TCP_CONNECTIONS
#define MB_RX_CAPACITY (2 * MB_BUFFER_SIZE)
#define MB_DEFAULT_TIMEOUT_MS 1000U
#define MB_DEFAULT_TCP_IDLE_MS 40000U

#endif
