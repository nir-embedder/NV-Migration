/* SPDX-License-Identifier: LGPL-2.1-only
 * RTU adapter derived from upstream MODBUS-LIB/Src/Modbus.c (sendTxBuffer,
 * getRxBuffer and master/slave workers), 9c022fd2538edb5b53e2e07c98ebbe9a4685546c.
 * Original author: Alejandro Mera (May 5, 2020), adapted from
 * https://github.com/smarmengol/Modbus-Master-Slave-for-Arduino.
 * Modified 2026-10-28 for NV-Migration: Zephyr interrupt UART, partial FIFO writes,
 * bounded byte streams, CDC length/CRC assembly and UART-derived silence timing.
 */
#include "Modbus.h"
#include <zephyr/drivers/uart.h>
#include <errno.h>
#include <string.h>

static uint64_t now_us(void)
{
#ifdef CONFIG_TIMER_HAS_64BIT_CYCLE_COUNTER
	return k_cyc_to_us_floor64(k_cycle_get_64());
#else
	/* Extend the cycle counter; coarse uptime disambiguates whole wraps
	 * even after a long application bank-lock wait or stopped interval.
	 */
	static struct k_spinlock clock_lock;
	static uint32_t previous;
	static uint64_t previous_ticks;
	static uint64_t extended;
	k_spinlock_key_t key = k_spin_lock(&clock_lock);
	uint32_t cycles = k_cycle_get_32();
	uint64_t ticks = (uint64_t)k_uptime_ticks();
	uint64_t estimate = k_ticks_to_cyc_floor64(ticks - previous_ticks);
	uint64_t delta = (uint32_t)(cycles - previous);

	if (estimate > delta && estimate - delta > (UINT64_C(1) << 31)) {
		delta += ((estimate - delta + (UINT64_C(1) << 31)) >> 32) << 32;
	}
	extended += delta;
	previous = cycles;
	previous_ticks = ticks;
	uint64_t us = k_cyc_to_us_floor64(extended);

	k_spin_unlock(&clock_lock, key);
	return us;
#endif
}

void mb_rtu_ingress(modbusHandler_t *h, const uint8_t *data, size_t len, uint64_t now)
{
	struct mb_private *p = &h->_private;
	k_spinlock_key_t key = k_spin_lock(&p->io_lock);
	uint8_t gap = 0;

	if (!p->io_enabled || atomic_get(&p->reset)) {
		k_spin_unlock(&p->io_lock, key);
		return;
	}
	if (p->last_rx_us != 0U) {
		uint64_t elapsed = now - p->last_rx_us;

		if (h->xTypeHW == USART_HW) {
			gap = elapsed >= p->t35_us ? 1U : (elapsed > p->t15_us ? 2U : 0U);
		} else if (elapsed >= (uint64_t)CONFIG_MODBUS_PORT_CDC_ASSEMBLY_MS * 1000U) {
			gap = 1U;
		}
	}
	for (size_t i = 0; i < len; i++) {
		if (p->rx_count == MB_RX_CAPACITY) {
			p->rx_overflow = true;
			break;
		}
		size_t at = (p->rx_head + p->rx_count) % MB_RX_CAPACITY;

		p->rx[at] = data[i];
		p->rx_gap[at] = i == 0U ? gap : 0U;
		p->rx_count++;
	}
	if (len != 0U) {
		p->last_rx_us = now;
	}
	k_spin_unlock(&p->io_lock, key);
	k_sem_give(&p->wake);
}

static void uart_callback(const struct device *dev, void *arg)
{
	modbusHandler_t *h = arg;
	struct mb_private *p = &h->_private;

	/* Bound callback work even if a broken peripheral never deasserts IRQ. */
	for (unsigned int pass = 0; pass < 16U; pass++) {
		bool progressed = false;

		uart_irq_update(dev);
		if (uart_irq_is_pending(dev) <= 0) {
			break;
		}
		if (uart_irq_rx_ready(dev) > 0) {
			uint8_t bytes[32];
			int n = uart_fifo_read(dev, bytes, sizeof(bytes));

			if (n > 0) {
				mb_rtu_ingress(h, bytes, (size_t)n, now_us());
				progressed = true;
			} else if (n < 0) {
				k_spinlock_key_t key = k_spin_lock(&p->io_lock);

				p->io_error = n;
				k_spin_unlock(&p->io_lock, key);
				k_sem_give(&p->wake);
			}
		}
		if (uart_irq_tx_ready(dev) > 0) {
			k_spinlock_key_t key = k_spin_lock(&p->io_lock);

			if (!p->io_enabled || atomic_get(&p->reset) || p->tx_offset == p->tx_len) {
				uart_irq_tx_disable(dev);
			} else {
				int n = uart_fifo_fill(dev, p->tx + p->tx_offset,
						      (int)(p->tx_len - p->tx_offset));

				if (n > 0 && (size_t)n <= p->tx_len - p->tx_offset) {
					p->tx_offset += (size_t)n;
					progressed = true;
				} else if (n == 0) {
					/* Backpressure must not cause a level-IRQ storm. The
					 * worker retries admission on its next bounded step.
					 */
					uart_irq_tx_disable(dev);
				} else {
					p->io_error = n < 0 ? n : -EIO;
					uart_irq_tx_disable(dev);
				}
				if (p->tx_offset == p->tx_len) {
					p->tx_empty_us = now_us();
					uart_irq_tx_disable(dev);
				}
			}
			k_spin_unlock(&p->io_lock, key);
			k_sem_give(&p->wake);
		}
		if (!progressed) {
			break;
		}
	}
}

void mb_rtu_reset(modbusHandler_t *h)
{
	struct mb_private *p = &h->_private;
	k_spinlock_key_t key;

	uart_irq_tx_disable(h->port);
	key = k_spin_lock(&p->io_lock);
	p->rx_head = 0;
	p->rx_count = 0;
	p->rx_overflow = false;
	p->io_error = 0;
	p->last_rx_us = 0;
	p->tx_len = 0;
	p->tx_offset = 0;
	p->tx_pending = false;
	p->quiet_until_us = now_us() + p->t35_us;
	k_spin_unlock(&p->io_lock, key);
	p->frame_len = 0;
	p->frame_invalid = false;
	p->cdc_discard = false;
}

int mb_rtu_start(modbusHandler_t *h)
{
	struct mb_private *p = &h->_private;
	int ret;

	p->t15_us = 0;
	p->t35_us = 0;
	if (h->xTypeHW == USART_HW) {
		struct uart_config cfg;

		ret = uart_config_get(h->port, &cfg);
		if (ret != 0) {
			return ret;
		}
		if (cfg.baudrate == 0U || cfg.data_bits != UART_CFG_DATA_BITS_8 ||
		    (cfg.stop_bits != UART_CFG_STOP_BITS_1 && cfg.stop_bits != UART_CFG_STOP_BITS_2) ||
		    (cfg.parity != UART_CFG_PARITY_NONE && cfg.parity != UART_CFG_PARITY_EVEN &&
		     cfg.parity != UART_CFG_PARITY_ODD) || cfg.flow_ctrl != UART_CFG_FLOW_CTRL_NONE) {
			return -ENOTSUP;
		}
		uint32_t bits = 1U + 8U + (cfg.parity != UART_CFG_PARITY_NONE ? 1U : 0U) +
			(cfg.stop_bits == UART_CFG_STOP_BITS_2 ? 2U : 1U);

		p->char_us = (uint32_t)DIV_ROUND_UP((uint64_t)bits * 1000000U, cfg.baudrate);
		p->t15_us = cfg.baudrate > 19200U ? 750U :
			(uint32_t)DIV_ROUND_UP((uint64_t)bits * 1500000U, cfg.baudrate);
		p->t35_us = cfg.baudrate > 19200U ? 1750U :
			(uint32_t)DIV_ROUND_UP((uint64_t)bits * 3500000U, cfg.baudrate);
	}
	mb_rtu_reset(h);
	ret = uart_irq_callback_user_data_set(h->port, uart_callback, h);
	if (ret != 0) {
		return ret;
	}
	k_spinlock_key_t key = k_spin_lock(&p->io_lock);

	p->io_enabled = true;
	k_spin_unlock(&p->io_lock, key);
	uart_irq_rx_enable(h->port);
	return 0;
}

void mb_rtu_stop(modbusHandler_t *h)
{
	struct mb_private *p = &h->_private;
	k_spinlock_key_t key = k_spin_lock(&p->io_lock);

	p->io_enabled = false;
	k_spin_unlock(&p->io_lock, key);
	uart_irq_rx_disable(h->port);
	uart_irq_tx_disable(h->port);
	/* Static handler lifetime also covers a callback already queued by CDC. */
	mb_rtu_reset(h);
}

static void transmit(modbusHandler_t *h, const uint8_t *frame, size_t len)
{
	struct mb_private *p = &h->_private;
	k_spinlock_key_t key = k_spin_lock(&p->io_lock);

	memcpy(p->tx, frame, len);
	p->tx_len = len;
	p->tx_offset = 0;
	p->tx_pending = true;
	p->tx_empty_us = 0;
	p->tx_deadline = k_uptime_get() + h->u16timeOut;
	k_spin_unlock(&p->io_lock, key);
	uart_irq_tx_enable(h->port);
}

static bool write_function(uint8_t function)
{
	return function == 5U || function == 6U || function == 15U || function == 16U;
}

static void frame_received(modbusHandler_t *h, size_t len)
{
	struct mb_private *p = &h->_private;
	uint8_t reply[MB_BUFFER_SIZE];
	uint16_t crc;
	int n;

	if (len < 4U || p->frame_invalid) {
		return;
	}
	crc = calcCRC(p->frame, len - 2U);
	if (p->frame[len - 2U] != (uint8_t)crc || p->frame[len - 1U] != (uint8_t)(crc >> 8)) {
		return;
	}
	if (h->uModbusType == MB_MASTER) {
		if (p->active_valid && p->frame[0] == p->active.u8id) {
			n = mb_core_parse(&p->active, p->frame + 1, len - 3U);
			mb_complete(h, n);
		}
		return;
	}
	if (p->frame[0] != h->u8id && p->frame[0] != 0U) {
		return;
	}
	if (p->frame[0] == 0U && !write_function(p->frame[1])) {
		return;
	}
	n = mb_server(h, p->frame + 1, len - 3U, reply + 1, sizeof(reply) - 3U);
	if (n > 0 && p->frame[0] != 0U) {
		reply[0] = h->u8id;
		crc = calcCRC(reply, (size_t)n + 1U);
		reply[n + 1] = (uint8_t)crc;
		reply[n + 2] = (uint8_t)(crc >> 8);
		transmit(h, reply, (size_t)n + 3U);
	}
}

static bool tx_busy(modbusHandler_t *h, uint64_t now)
{
	struct mb_private *p = &h->_private;
	k_spinlock_key_t key = k_spin_lock(&p->io_lock);
	bool busy = p->tx_pending;

	if (busy && p->tx_offset == p->tx_len) {
		/* FIFO acceptance is not wire completion. Reserve a conservative
		 * whole-frame airtime plus T3.5 for physical UART; no DE control.
		 */
		uint64_t drain = h->xTypeHW == USART_HW ?
			(uint64_t)p->tx_len * p->char_us + p->t35_us : 0U;

		if (now >= p->tx_empty_us + drain) {
			p->tx_pending = false;
			p->quiet_until_us = now;
			busy = false;
		}
	}
	k_spin_unlock(&p->io_lock, key);
	return busy;
}

static bool pop_byte(modbusHandler_t *h, uint8_t *byte, uint8_t *gap)
{
	struct mb_private *p = &h->_private;
	k_spinlock_key_t key = k_spin_lock(&p->io_lock);
	bool found = p->rx_count != 0U;

	if (found) {
		*byte = p->rx[p->rx_head];
		*gap = p->rx_gap[p->rx_head];
		p->rx_head = (p->rx_head + 1U) % MB_RX_CAPACITY;
		p->rx_count--;
	}
	k_spin_unlock(&p->io_lock, key);
	return found;
}

void mb_rtu_step(modbusHandler_t *h)
{
	struct mb_private *p = &h->_private;
	uint64_t now = now_us();
	int64_t ms = k_uptime_get();
	uint64_t last_rx;
	bool pending;
	bool overflow;
	int io_error;
	uint8_t byte, gap;
	k_spinlock_key_t key = k_spin_lock(&p->io_lock);

	overflow = p->rx_overflow;
	io_error = p->io_error;
	last_rx = p->last_rx_us;
	k_spin_unlock(&p->io_lock, key);
	if (overflow || io_error != 0) {
		mb_rtu_reset(h);
		mb_complete(h, overflow ? -ENOBUFS : io_error);
		return;
	}
	pending = tx_busy(h, now);
	if ((pending && ms >= p->tx_deadline) || (p->active_valid && ms >= p->deadline)) {
		mb_rtu_reset(h);
		mb_complete(h, -ETIMEDOUT);
		return;
	}
	if (pending) {
		key = k_spin_lock(&p->io_lock);
		bool remaining = p->tx_offset < p->tx_len;

		k_spin_unlock(&p->io_lock, key);
		if (remaining) {
			uart_irq_tx_enable(h->port);
		}
		return;
	}
	if (p->active_valid && p->active.u8id == 0U) {
		mb_complete(h, 0);
	}
	/* Keep input queued during output backpressure, then consume complete ADUs
	 * one at a time. Never infer an ADU boundary from a USB callback.
	 */
	while (pop_byte(h, &byte, &gap)) {
		if (gap == 1U) {
			int expected = mb_rtu_frame_length(p->frame, p->frame_len,
							 h->uModbusType == MB_MASTER);

			if (p->frame_len != 0U && !p->cdc_discard &&
			    (h->xTypeHW == USART_HW || expected == -ENOTSUP)) {
				frame_received(h, p->frame_len);
			}
			p->frame_len = 0;
			p->frame_invalid = false;
			p->cdc_discard = false;
		} else if (gap == 2U) {
			p->frame_invalid = true;
		}
		if (p->frame_len == sizeof(p->frame)) {
			p->frame_invalid = true;
			p->cdc_discard = true;
		} else {
			p->frame[p->frame_len++] = byte;
		}
		if (h->xTypeHW == USB_CDC_HW && !p->cdc_discard) {
			int expected = mb_rtu_frame_length(p->frame, p->frame_len,
							 h->uModbusType == MB_MASTER);

			if (expected > (int)sizeof(p->frame) || (expected < 0 && expected != -ENOTSUP)) {
				p->cdc_discard = true;
			} else if (expected > 0 && p->frame_len == (size_t)expected) {
				frame_received(h, p->frame_len);
				p->frame_len = 0;
				p->frame_invalid = false;
			}
		}
		if (tx_busy(h, now)) {
			return;
		}
	}
	/* Recheck after draining: an ISR may have appended more recently than
	 * the snapshot taken at the beginning of this worker iteration.
	 */
	key = k_spin_lock(&p->io_lock);
	last_rx = p->last_rx_us;
	bool rx_empty = p->rx_count == 0U;

	k_spin_unlock(&p->io_lock, key);
	if (rx_empty && p->frame_len != 0U &&
	    ((h->xTypeHW == USART_HW && now >= last_rx + p->t35_us) ||
	     (h->xTypeHW == USB_CDC_HW &&
	      now >= last_rx + (uint64_t)CONFIG_MODBUS_PORT_CDC_ASSEMBLY_MS * 1000U))) {
		int expected = mb_rtu_frame_length(p->frame, p->frame_len,
						 h->uModbusType == MB_MASTER);

		if (!p->cdc_discard && (expected == -ENOTSUP || expected == (int)p->frame_len)) {
			frame_received(h, p->frame_len);
		}
		p->frame_len = 0;
		p->frame_invalid = false;
		p->cdc_discard = false;
	}
	if (h->uModbusType == MB_MASTER && !p->active_valid && !tx_busy(h, now) &&
	    p->frame_len == 0U && now >= p->quiet_until_us &&
	    (h->xTypeHW != USART_HW || now >= last_rx + p->t35_us) && mb_take_query(h)) {
		uint8_t request[MB_BUFFER_SIZE];
		int n;

		if (p->active.u8id == 0U && !write_function(p->active.u8fct)) {
			mb_complete(h, -EINVAL);
			return;
		}
		n = mb_core_build(&p->active, request + 1, sizeof(request) - 3U);
		if (n < 0) {
			mb_complete(h, n);
			return;
		}
		request[0] = p->active.u8id;
		uint16_t crc = calcCRC(request, (size_t)n + 1U);

		request[n + 1] = (uint8_t)crc;
		request[n + 2] = (uint8_t)(crc >> 8);
		transmit(h, request, (size_t)n + 3U);
	}
}
