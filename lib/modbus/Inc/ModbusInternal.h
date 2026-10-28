/* SPDX-License-Identifier: LGPL-2.1-only
 * Private static storage for the Zephyr adaptation of upstream Modbus.c
 * (9c022fd2538edb5b53e2e07c98ebbe9a4685546c). Not an application API.
 * Modified 2026-10-28 for NV-Migration: bounded Zephyr transport/worker storage.
 */
#ifndef MODBUS_PORT_INTERNAL_H
#define MODBUS_PORT_INTERNAL_H

#include <zephyr/kernel.h>
#include <zephyr/sys/atomic.h>
#include "ModbusConfig.h"
#include "ModbusCore.h"

struct modbusHandler;

struct mb_tcp_peer {
	int fd;
	bool connecting;
	uint32_t address;
	uint16_t port;
	int64_t last_activity;
	uint8_t rx[MB_TCP_BUFFER_SIZE];
	size_t rx_len;
	uint8_t tx[MB_TCP_BUFFER_SIZE];
	size_t tx_len;
	size_t tx_offset;
};

struct mb_private {
	atomic_t initialized;
	atomic_t state;
	atomic_t reset;
	struct k_spinlock queue_lock;
	struct k_sem wake;
	struct k_thread worker;
	K_KERNEL_STACK_MEMBER(stack, CONFIG_MODBUS_PORT_STACK_SIZE);
	modbus_t queue[MB_QUEUE_DEPTH];
	size_t queue_head;
	size_t queue_count;
	modbus_t active;
	bool active_valid;
	int64_t deadline;
	uint16_t transaction;

	struct k_spinlock io_lock;
	bool io_enabled;
	bool rx_overflow;
	int io_error;
	uint8_t rx[MB_RX_CAPACITY];
	uint8_t rx_gap[MB_RX_CAPACITY];
	size_t rx_head;
	size_t rx_count;
	uint64_t last_rx_us;
	uint64_t quiet_until_us;
	uint32_t t15_us;
	uint32_t t35_us;
	uint32_t char_us;
	uint8_t tx[MB_BUFFER_SIZE];
	size_t tx_len;
	size_t tx_offset;
	bool tx_pending;
	uint64_t tx_empty_us;
	uint8_t frame[MB_BUFFER_SIZE];
	size_t frame_len;
	bool frame_invalid;
	bool cdc_discard;
	int64_t tx_deadline;

	int listener;
	struct mb_tcp_peer peers[MB_TCP_CONNECTIONS];
};

enum { MB_STOPPED, MB_RUNNING, MB_STOPPING };

/* Worker-only helpers, except the explicitly ISR-safe receive ingress. */
bool mb_take_query(struct modbusHandler *h);
void mb_complete(struct modbusHandler *h, int result);
int mb_server(struct modbusHandler *h, const uint8_t *pdu, size_t length,
	      uint8_t *reply, size_t capacity);
int mb_rtu_start(struct modbusHandler *h);
void mb_rtu_stop(struct modbusHandler *h);
void mb_rtu_reset(struct modbusHandler *h);
void mb_rtu_step(struct modbusHandler *h);
void mb_rtu_ingress(struct modbusHandler *h, const uint8_t *data, size_t len,
		    uint64_t now_us);
int mb_tcp_start(struct modbusHandler *h);
void mb_tcp_stop(struct modbusHandler *h);
void mb_tcp_reset(struct modbusHandler *h);
void mb_tcp_step(struct modbusHandler *h);
/* Returns full TCP ADU length, zero until the six-byte prefix is available. */
int mb_tcp_adu_length(const uint8_t *data, size_t length);

#endif
