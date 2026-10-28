/* SPDX-License-Identifier: LGPL-2.1-only
 * Derived from Alejandro Mera's MODBUS-LIB/Src/Modbus.c, upstream commit
 * 9c022fd2538edb5b53e2e07c98ebbe9a4685546c (Init/Start/query task lifecycle).
 * Original author: Alejandro Mera (May 5, 2020), adapted from
 * https://github.com/smarmengol/Modbus-Master-Slave-for-Arduino.
 * Modified 2026-10-28 for NV-Migration: no globals for protocol state, allocation
 * or task notifications; bounded Zephyr queue, worker ownership and completions.
 */
#include "Modbus.h"
#include <errno.h>
#include <string.h>

K_MUTEX_DEFINE(lifecycle_lock);
static modbusHandler_t *running[CONFIG_MODBUS_PORT_MAX_HANDLERS];

static void finish(modbus_t *q, int result)
{
	struct modbus_completion *c = q->completion;

	/* Detach all caller pointers before publishing ownership release. */
	memset(q, 0, sizeof(*q));
	c->result = result;
	atomic_clear(&c->in_flight);
	k_sem_give(&c->sem); /* Last access to caller-owned completion. */
}

void mb_complete(modbusHandler_t *h, int result)
{
	struct mb_private *p = &h->_private;

	if (p->active_valid) {
		p->active_valid = false;
		finish(&p->active, result);
	}
}

bool mb_take_query(modbusHandler_t *h)
{
	struct mb_private *p = &h->_private;
	k_spinlock_key_t key = k_spin_lock(&p->queue_lock);
	bool found = false;

	if (!p->active_valid && p->queue_count != 0U &&
	    atomic_get(&p->state) == MB_RUNNING && !atomic_get(&p->reset)) {
		p->active = p->queue[p->queue_head];
		memset(&p->queue[p->queue_head], 0, sizeof(modbus_t));
		p->queue_head = (p->queue_head + 1U) % MB_QUEUE_DEPTH;
		p->queue_count--;
		p->active_valid = true;
		p->deadline = k_uptime_get() + h->u16timeOut;
		found = true;
	}
	k_spin_unlock(&p->queue_lock, key);
	return found;
}

static void cancel_all(modbusHandler_t *h, int result, bool clear_reset)
{
	struct mb_private *p = &h->_private;
	modbus_t canceled[MB_QUEUE_DEPTH + 1];
	size_t count = 0;
	k_spinlock_key_t key = k_spin_lock(&p->queue_lock);

	if (p->active_valid) {
		canceled[count++] = p->active;
		memset(&p->active, 0, sizeof(p->active));
		p->active_valid = false;
	}
	while (p->queue_count != 0U) {
		canceled[count++] = p->queue[p->queue_head];
		memset(&p->queue[p->queue_head], 0, sizeof(modbus_t));
		p->queue_head = (p->queue_head + 1U) % MB_QUEUE_DEPTH;
		p->queue_count--;
	}
	if (clear_reset) {
		/* A new notification during cleanup must not be lost. Detach the
		 * old queue before reopening admission or releasing any completion.
		 */
		atomic_cas(&p->reset, 2, 0);
	}
	k_spin_unlock(&p->queue_lock, key);
	for (size_t i = 0; i < count; i++) {
		finish(&canceled[i], result);
	}
}

int mb_server(modbusHandler_t *h, const uint8_t *pdu, size_t len,
	      uint8_t *reply, size_t cap)
{
	int ret;

	if (h->memory_lock != NULL) {
		/* Finite lock wait is important: Stop must not wait forever for an
		 * application holding the bank lock while shutting down transports.
		 */
		ret = k_mutex_lock(h->memory_lock, K_MSEC(h->u16timeOut));
		if (ret != 0) {
			if (cap < 2U || len == 0U) {
				return -ENOSPC;
			}
			reply[0] = pdu[0] | 0x80U;
			reply[1] = 6U; /* Server device busy. */
			return 2;
		}
	}
	ret = mb_core_server(&h->memory, pdu, len, reply, cap);
	if (h->memory_lock != NULL) {
		k_mutex_unlock(h->memory_lock);
	}
	return ret;
}

static void transport_reset(modbusHandler_t *h)
{
	if (h->xTypeHW == TCP_HW) {
#ifdef CONFIG_MODBUS_PORT_TCP
		mb_tcp_reset(h);
#endif
	} else {
#ifdef CONFIG_MODBUS_PORT_RTU
		mb_rtu_reset(h);
#endif
	}
}

static void transport_stop(modbusHandler_t *h)
{
	if (h->xTypeHW == TCP_HW) {
#ifdef CONFIG_MODBUS_PORT_TCP
		mb_tcp_stop(h);
#endif
	} else {
#ifdef CONFIG_MODBUS_PORT_RTU
		mb_rtu_stop(h);
#endif
	}
}

static void worker(void *arg, void *unused1, void *unused2)
{
	modbusHandler_t *h = arg;
	struct mb_private *p = &h->_private;

	ARG_UNUSED(unused1);
	ARG_UNUSED(unused2);
	while (atomic_get(&p->state) == MB_RUNNING) {
		if (atomic_cas(&p->reset, 1, 2)) {
			transport_reset(h);
			cancel_all(h, -ECONNRESET, true);
			continue;
		}
		if (h->xTypeHW == TCP_HW) {
#ifdef CONFIG_MODBUS_PORT_TCP
			mb_tcp_step(h);
#endif
		} else {
#ifdef CONFIG_MODBUS_PORT_RTU
			mb_rtu_step(h);
#endif
		}
		/* Notifications carry no stale timeout data. All deadlines are
		 * rechecked against the currently worker-owned transaction.
		 */
		k_sem_take(&p->wake, K_MSEC(1));
	}
	transport_stop(h);
	cancel_all(h, -ECANCELED, false);
}

int ModbusInit(modbusHandler_t *h)
{
	if (h == NULL || k_is_in_isr()) {
		return -EINVAL;
	}
	if (atomic_get(&h->_private.initialized)) {
		return -EALREADY;
	}
	if (h->xTypeHW == USART_HW_DMA) {
		return -ENOTSUP;
	}
	if ((h->uModbusType != MB_MASTER && h->uModbusType != MB_SLAVE) ||
	    (h->xTypeHW != USART_HW && h->xTypeHW != USB_CDC_HW && h->xTypeHW != TCP_HW) ||
	    (h->uModbusType == MB_MASTER && h->u8id != 0U) ||
	    (h->uModbusType == MB_SLAVE && (h->u8id == 0U || h->u8id > 247U))) {
		return -EINVAL;
	}
	if ((h->xTypeHW == TCP_HW && !IS_ENABLED(CONFIG_MODBUS_PORT_TCP)) ||
	    (h->xTypeHW != TCP_HW && !IS_ENABLED(CONFIG_MODBUS_PORT_RTU))) {
		return -ENOTSUP;
	}
	if (h->xTypeHW != TCP_HW && (h->port == NULL || !device_is_ready(h->port))) {
		return -ENODEV;
	}
	if (h->uModbusType == MB_SLAVE && h->memory.u16regs == NULL &&
	    h->memory.u16coils == NULL && h->memory.u16discreteInputs == NULL &&
	    h->memory.u16holdingRegs == NULL && h->memory.u16inputRegs == NULL) {
		return -EINVAL;
	}
	if (h->u16timeOut == 0U) {
		h->u16timeOut = MB_DEFAULT_TIMEOUT_MS;
	}
	if (h->uTcpPort == 0U) {
		h->uTcpPort = 502U;
	}
	if (h->tcp_idle_ms == 0U) {
		h->tcp_idle_ms = MB_DEFAULT_TCP_IDLE_MS;
	}
	k_sem_init(&h->_private.wake, 0, 1);
	h->_private.listener = -1;
	for (size_t i = 0; i < MB_TCP_CONNECTIONS; i++) {
		h->_private.peers[i].fd = -1;
	}
	atomic_set(&h->_private.initialized, 1);
	return 0;
}

int ModbusStart(modbusHandler_t *h)
{
	int ret = -ENOTSUP;
	int slot = -1;

	if (h == NULL || k_is_in_isr() || !atomic_get(&h->_private.initialized)) {
		return -EINVAL;
	}
	k_mutex_lock(&lifecycle_lock, K_FOREVER);
	if (atomic_get(&h->_private.state) != MB_STOPPED) {
		ret = -EALREADY;
		goto out;
	}
	for (size_t i = 0; i < ARRAY_SIZE(running); i++) {
		if (running[i] == NULL) {
			slot = (int)i;
		} else if (h->xTypeHW != TCP_HW && running[i]->xTypeHW != TCP_HW &&
			   running[i]->port == h->port) {
			ret = -EBUSY;
			goto out;
		}
	}
	if (slot < 0) {
		ret = -ENOSPC;
		goto out;
	}
	atomic_clear(&h->_private.reset);
	if (h->xTypeHW == TCP_HW) {
#ifdef CONFIG_MODBUS_PORT_TCP
		ret = mb_tcp_start(h);
#endif
	} else {
#ifdef CONFIG_MODBUS_PORT_RTU
		ret = mb_rtu_start(h);
#endif
	}
	if (ret == 0) {
		running[slot] = h;
		atomic_set(&h->_private.state, MB_RUNNING);
		k_thread_create(&h->_private.worker, h->_private.stack,
				K_KERNEL_STACK_SIZEOF(h->_private.stack), worker, h, NULL, NULL,
				CONFIG_MODBUS_PORT_THREAD_PRIORITY, 0, K_NO_WAIT);
	}
out:
	k_mutex_unlock(&lifecycle_lock);
	return ret;
}

int ModbusStartCDC(modbusHandler_t *h)
{
	if (h == NULL || h->xTypeHW != USB_CDC_HW) {
		return -EINVAL;
	}
	return ModbusStart(h);
}

int ModbusStop(modbusHandler_t *h)
{
	if (h == NULL || k_is_in_isr() || !atomic_get(&h->_private.initialized)) {
		return -EINVAL;
	}
	if (k_current_get() == &h->_private.worker) {
		return -EDEADLK;
	}
	k_mutex_lock(&lifecycle_lock, K_FOREVER);
	if (atomic_get(&h->_private.state) != MB_STOPPED) {
		atomic_set(&h->_private.state, MB_STOPPING);
		k_sem_give(&h->_private.wake);
		k_thread_join(&h->_private.worker, K_FOREVER);
		atomic_set(&h->_private.state, MB_STOPPED);
		for (size_t i = 0; i < ARRAY_SIZE(running); i++) {
			if (running[i] == h) {
				running[i] = NULL;
			}
		}
	}
	k_mutex_unlock(&lifecycle_lock);
	return 0;
}

void ModbusCompletionInit(struct modbus_completion *c)
{
	if (c != NULL) {
		k_sem_init(&c->sem, 0, 1);
		c->result = 0;
		atomic_clear(&c->in_flight);
	}
}

static int enqueue(modbusHandler_t *h, modbus_t q, bool front)
{
	struct mb_private *p;
	k_spinlock_key_t key;
	int ret = 0;
	size_t index;

	if (h == NULL || q.completion == NULL || !atomic_get(&h->_private.initialized)) {
		return -EINVAL;
	}
	if (h->uModbusType != MB_MASTER) {
		return -EPERM;
	}
	if (q.u8id > 247U || (h->xTypeHW == TCP_HW &&
	    (q.u8id == 0U || q.u8clientID >= MB_TCP_CONNECTIONS))) {
		return -EINVAL;
	}
	p = &h->_private;
	key = k_spin_lock(&p->queue_lock);
	if (atomic_get(&p->state) != MB_RUNNING) {
		ret = -ESHUTDOWN;
	} else if (atomic_get(&p->reset)) {
		ret = -ECONNRESET;
	} else if (p->queue_count == MB_QUEUE_DEPTH) {
		ret = -ENOSPC;
	} else if (!atomic_cas(&q.completion->in_flight, 0, 1)) {
		ret = -EBUSY;
	} else {
		k_sem_reset(&q.completion->sem);
		if (front) {
			p->queue_head = (p->queue_head + MB_QUEUE_DEPTH - 1U) % MB_QUEUE_DEPTH;
		}
		index = front ? p->queue_head : (p->queue_head + p->queue_count) % MB_QUEUE_DEPTH;
		p->queue[index] = q;
		p->queue_count++;
	}
	k_spin_unlock(&p->queue_lock, key);
	if (ret == 0) {
		k_sem_give(&p->wake);
	}
	return ret;
}

int ModbusQuery(modbusHandler_t *h, modbus_t q)
{
	return enqueue(h, q, false);
}

int ModbusQueryInject(modbusHandler_t *h, modbus_t q)
{
	return enqueue(h, q, true);
}

int ModbusQueryV2(modbusHandler_t *h, modbus_t q)
{
	struct modbus_completion completion;
	int ret;

	if (h == NULL || k_is_in_isr()) {
		return -EINVAL;
	}
	if (k_current_get() == &h->_private.worker) {
		return -EDEADLK;
	}
	ModbusCompletionInit(&completion);
	q.completion = &completion;
	ret = ModbusQuery(h, q);
	if (ret != 0) {
		return ret;
	}
	/* No independent caller timeout: the worker must acknowledge cancellation
	 * or finish parsing before a stack completion/payload can be released.
	 */
	k_sem_take(&completion.sem, K_FOREVER);
	return completion.result;
}

void ModbusTransportReset(modbusHandler_t *h)
{
	if (h != NULL && atomic_get(&h->_private.initialized)) {
		atomic_set(&h->_private.reset, 1);
		k_sem_give(&h->_private.wake);
	}
}
