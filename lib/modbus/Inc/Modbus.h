/* SPDX-License-Identifier: LGPL-2.1-only
 * Zephyr port of Alejandro Mera's Modbus-STM32-HAL-FreeRTOS public API.
 * Upstream: 9c022fd2538edb5b53e2e07c98ebbe9a4685546c, MODBUS-LIB/Inc/Modbus.h.
 * Modified 2026-10-28 for NV-Migration: native Zephyr lifecycle, bounded storage
 * and explicit completions.
 */
#ifndef MODBUS_PORT_H
#define MODBUS_PORT_H

#include <zephyr/device.h>
#include <zephyr/kernel.h>
#include <zephyr/sys/atomic.h>
#include "ModbusCore.h"
#include "ModbusInternal.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef enum {
	USART_HW = 1, USB_CDC_HW = 2, TCP_HW = 3, USART_HW_DMA = 4
} mb_hardware_t;
typedef enum { MB_SLAVE = 3, MB_MASTER = 4 } mb_masterslave_t;

struct modbus_completion {
	struct k_sem sem;
	int result; /* 0 success, positive Modbus exception, negative errno. */
	atomic_t in_flight;
};

/* Statically allocate/zero-initialize; configure only the fields above _private.
 * Configuration and memory mappings must remain unchanged between Init and Stop.
 * Each UART device may belong to only one running handler. USART_HW is IRQ-based
 * full-duplex UART only: no RS-485 DE/RE timing or DMA implementation is supplied.
 */
typedef struct modbusHandler {
	mb_masterslave_t uModbusType;
	mb_hardware_t xTypeHW;
	const struct device *port;
	uint8_t u8id; /* Master 0; server 1..247. */
	mb_memory_t memory;
	struct k_mutex *memory_lock; /* Optional shared-bank lock; core access only. */
	uint32_t u16timeOut; /* Milliseconds, zero selects 1000 ms. */
	uint16_t uTcpPort; /* Server listen port, zero selects 502. */
	uint32_t tcp_idle_ms; /* Zero selects 40000 ms (upstream 4*1000*10). */
	struct mb_private _private; /* Library-owned; never inspect or mutate. */
} modbusHandler_t;

/* Init/Start/Stop are thread-context operations. Init requires static zeroed
 * storage, and is idempotent (-EALREADY on a second initialization). Stop joins
 * the worker and completes all accepted requests with -ECANCELED. Start after
 * Stop is supported. No API allocates dynamic memory or waits for USB DTR.
 */
int ModbusInit(modbusHandler_t *handler);
int ModbusStart(modbusHandler_t *handler);
int ModbusStartCDC(modbusHandler_t *handler);
int ModbusStop(modbusHandler_t *handler);

/* Initialize only while the completion is not owned by a submitted request.
 * Async APIs copy telegram metadata; payload and completion must remain valid
 * and unmodified until k_sem_take(&completion.sem, ...) succeeds. On enqueue
 * failure ownership never transfers. A completion may have only one owner.
 * Inject prepends without dropping existing requests. Queue-full is -ENOSPC.
 */
void ModbusCompletionInit(struct modbus_completion *completion);
int ModbusQuery(modbusHandler_t *handler, modbus_t telegram);
int ModbusQueryInject(modbusHandler_t *handler, modbus_t telegram);
/* Blocking, uses its own completion, ignores telegram.completion. On return
 * no library code can access the caller payload. Do not call from ISR/worker.
 * Timeout applies to each active transaction, not time spent in the queue.
 */
int ModbusQueryV2(modbusHandler_t *handler, modbus_t telegram);

/* ISR/callback-safe notification. Worker discards partial transport state and
 * fails accepted requests with -ECONNRESET; no parser, socket or mutex in caller.
 * Call for USB bus reset, unplug, or DTR close (USB lifecycle owned by app).
 * The UART API cannot retract bytes already queued inside the USB driver;
 * the application's USB lifecycle must handle those opaque driver buffers.
 */
void ModbusTransportReset(modbusHandler_t *handler);

#ifdef __cplusplus
}
#endif
#endif
