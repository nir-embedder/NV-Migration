/* SPDX-License-Identifier: LGPL-2.1-only
 * Software-only Zephyr lifecycle and stream integration tests. The test UART
 * implements the real IRQ UART API, deliberately accepting three TX bytes.
 */
#include <zephyr/ztest.h>
#include <zephyr/irq_offload.h>
#include <zephyr/drivers/uart.h>
#include <zephyr/sys/byteorder.h>
#include "Modbus.h"
#include <errno.h>
#include <string.h>
#ifdef CONFIG_MODBUS_PORT_TCP
#include <zephyr/net/socket.h>
#endif

static modbusHandler_t handler;
#ifdef CONFIG_MODBUS_PORT_TCP
static modbusHandler_t second;
#endif
static uint16_t bank[128];
static struct {
	uart_irq_callback_user_data_t callback;
	void *arg;
	bool tx_enabled;
	bool rx_enabled;
	bool stalled;
	uint8_t tx[MB_RX_CAPACITY];
	size_t tx_len;
	uint8_t rx[MB_RX_CAPACITY];
	size_t rx_len;
	size_t rx_offset;
	struct k_sem changed;
} fake;

static int fake_fill(const struct device *dev, const uint8_t *data, int len)
{
	ARG_UNUSED(dev);
	int count = MIN(len, 3);

	if (fake.stalled) {
		return 0;
	}
	zassert_true(fake.tx_len + count <= sizeof(fake.tx));
	memcpy(fake.tx + fake.tx_len, data, count);
	fake.tx_len += count;
	k_sem_give(&fake.changed);
	return count;
}

static int fake_read(const struct device *dev, uint8_t *data, int len)
{
	ARG_UNUSED(dev);
	size_t count = MIN((size_t)len, fake.rx_len - fake.rx_offset);

	memcpy(data, fake.rx + fake.rx_offset, count);
	fake.rx_offset += count;
	return (int)count;
}

static void fake_tx_on(const struct device *dev)
{
	fake.tx_enabled = true;
	fake.callback(dev, fake.arg);
}
static void fake_tx_off(const struct device *dev) { ARG_UNUSED(dev); fake.tx_enabled = false; }
static void fake_rx_on(const struct device *dev) { ARG_UNUSED(dev); fake.rx_enabled = true; }
static void fake_rx_off(const struct device *dev) { ARG_UNUSED(dev); fake.rx_enabled = false; }
static int fake_tx_ready(const struct device *dev) { ARG_UNUSED(dev); return fake.tx_enabled; }
static int fake_rx_ready(const struct device *dev)
{
	ARG_UNUSED(dev);
	return fake.rx_enabled && fake.rx_offset < fake.rx_len;
}
static int fake_pending(const struct device *dev)
{
	return fake_tx_ready(dev) || fake_rx_ready(dev);
}
static void fake_update(const struct device *dev) { ARG_UNUSED(dev); }
static void fake_callback_set(const struct device *dev, uart_irq_callback_user_data_t cb, void *arg)
{
	ARG_UNUSED(dev);
	fake.callback = cb;
	fake.arg = arg;
}
static int fake_config_get(const struct device *dev, struct uart_config *cfg)
{
	ARG_UNUSED(dev);
	*cfg = (struct uart_config){ .baudrate = 9600, .parity = UART_CFG_PARITY_EVEN,
		.stop_bits = UART_CFG_STOP_BITS_1, .data_bits = UART_CFG_DATA_BITS_8,
		.flow_ctrl = UART_CFG_FLOW_CTRL_NONE };
	return 0;
}
static DEVICE_API(uart, fake_api) = {
	.fifo_fill = fake_fill, .fifo_read = fake_read,
	.irq_tx_enable = fake_tx_on, .irq_tx_disable = fake_tx_off,
	.irq_rx_enable = fake_rx_on, .irq_rx_disable = fake_rx_off,
	.irq_tx_ready = fake_tx_ready, .irq_rx_ready = fake_rx_ready,
	.irq_is_pending = fake_pending, .irq_update = fake_update,
	.irq_callback_set = fake_callback_set, .config_get = fake_config_get,
};
DEVICE_DEFINE(test_uart, "modbus_test_uart", NULL, NULL, NULL, NULL,
	      POST_KERNEL, CONFIG_KERNEL_INIT_PRIORITY_DEVICE, &fake_api);

static void configure(mb_masterslave_t role, mb_hardware_t hw)
{
	handler.uModbusType = role;
	handler.xTypeHW = hw;
	handler.port = DEVICE_GET(test_uart);
	handler.u8id = role == MB_SLAVE ? 10 : 0;
	handler.memory.u16regs = bank;
	handler.memory.u16regsize = ARRAY_SIZE(bank);
	handler.u16timeOut = 100;
	handler.uTcpPort = 15020;
	zassert_ok(ModbusInit(&handler));
}

static void before(void *fixture)
{
	ARG_UNUSED(fixture);
	memset(&handler, 0, sizeof(handler));
	memset(&fake, 0, sizeof(fake));
	memset(bank, 0, sizeof(bank));
	k_sem_init(&fake.changed, 0, 1);
}
static void after(void *fixture)
{
	ARG_UNUSED(fixture);
	if (atomic_get(&handler._private.initialized)) {
		zassert_ok(ModbusStop(&handler));
	}
#ifdef CONFIG_MODBUS_PORT_TCP
	if (atomic_get(&second._private.initialized)) {
		zassert_ok(ModbusStop(&second));
	}
	if (handler.xTypeHW == TCP_HW) {
		/* Closed loopback endpoints consume TCP contexts in TIME_WAIT.
		 * Keep test cases isolated without disabling the stack's protection.
		 */
		k_msleep(CONFIG_NET_TCP_TIME_WAIT_DELAY + 10);
	}
#endif
}

static size_t add_crc(uint8_t *frame, size_t len)
{
	uint16_t crc = calcCRC(frame, len);

	frame[len] = (uint8_t)crc;
	frame[len + 1] = (uint8_t)(crc >> 8);
	return len + 2;
}
static void feed(const uint8_t *data, size_t len)
{
	zassert_true(len <= sizeof(fake.rx));
	memcpy(fake.rx, data, len);
	fake.rx_offset = 0;
	fake.rx_len = len;
	fake.callback(DEVICE_GET(test_uart), fake.arg);
}
static void wait_tx(size_t len)
{
	int64_t until = k_uptime_get() + 500;

	while (fake.tx_len < len && k_uptime_get() < until) {
		/* Emulate subsequent hardware IRQs after the bounded callback exits. */
		if (fake.tx_enabled && !fake.stalled) {
			fake.callback(DEVICE_GET(test_uart), fake.arg);
		}
		if (fake.tx_len < len) {
			k_sem_take(&fake.changed, K_MSEC(5));
		}
	}
	zassert_equal(fake.tx_len, len);
}
static void wait_rtu_frame(size_t expected)
{
	int64_t until = k_uptime_get() + 500;
	size_t length, queued;
	bool pending;

	do {
		/* qemu_cortex_m3 is uniprocessor. Exclude the worker while reading
		 * its frame state, and the IRQ callback while reading its FIFO.
		 */
		BUILD_ASSERT(!IS_ENABLED(CONFIG_SMP));
		k_sched_lock();
		k_spinlock_key_t key = k_spin_lock(&handler._private.io_lock);

		length = handler._private.frame_len;
		queued = handler._private.rx_count;
		pending = handler._private.tx_pending;
		k_spin_unlock(&handler._private.io_lock, key);
		k_sched_unlock();
		if (length == expected && queued == 0U && !pending) {
			return;
		}
		k_msleep(1);
	} while (k_uptime_get() < until);
	zassert_true(false, "frame %u expected %u, queued %u, TX pending %d",
		     (unsigned)length, (unsigned)expected, (unsigned)queued, pending);
}

static modbus_t query(struct modbus_completion *done, uint16_t *value, uint16_t address)
{
	return (modbus_t){ .u8id = 10, .u8fct = 6, .u16RegAdd = address,
		.u16CoilsNo = 1, .u16reg = value, .u16regCapacity = 1, .completion = done };
}

ZTEST(modbus_port, test_lifecycle)
{
	zassert_equal(ModbusStart(&handler), -EINVAL);
	handler.xTypeHW = USART_HW_DMA;
	zassert_equal(ModbusInit(&handler), -ENOTSUP);
	configure(MB_SLAVE, USB_CDC_HW);
	zassert_equal(ModbusInit(&handler), -EALREADY);
	zassert_equal(handler.tcp_idle_ms, 40000);
	zassert_ok(ModbusStartCDC(&handler));
	zassert_equal(ModbusStartCDC(&handler), -EALREADY);
	zassert_ok(ModbusStop(&handler));
	zassert_ok(ModbusStop(&handler));
	zassert_ok(ModbusStart(&handler));
}

ZTEST(modbus_port, test_cdc_all_splits_partial_fifo)
{
	uint8_t frame[8] = {10, 6, 0, 1, 0x12, 0x34};

	add_crc(frame, 6);
	configure(MB_SLAVE, USB_CDC_HW);
	zassert_ok(ModbusStartCDC(&handler));
	for (size_t split = 1; split < sizeof(frame); split++) {
		fake.tx_len = 0;
		feed(frame, split);
		k_msleep(2);
		zassert_equal(fake.tx_len, 0);
		feed(frame + split, sizeof(frame) - split);
		wait_tx(sizeof(frame));
		zassert_mem_equal(fake.tx, frame, sizeof(frame));
		zassert_equal(bank[1], 0x1234);
		k_msleep(2);
	}
}

ZTEST(modbus_port, test_cdc_coalesced_crc_broadcast)
{
	uint8_t frames[16] = {10, 6, 0, 0, 0, 11};
	uint8_t broadcast[8] = {0, 6, 0, 2, 0, 33};

	add_crc(frames, 6);
	memcpy(frames + 8, frames, 8);
	frames[11] = 1;
	frames[13] = 22;
	add_crc(frames + 8, 6);
	configure(MB_SLAVE, USB_CDC_HW);
	zassert_ok(ModbusStart(&handler));
	feed(frames, sizeof(frames));
	wait_tx(sizeof(frames));
	zassert_mem_equal(fake.tx, frames, sizeof(frames));
	zassert_equal(bank[0], 11);
	zassert_equal(bank[1], 22);
	k_msleep(2);
	fake.tx_len = 0;
	add_crc(broadcast, 6);
	feed(broadcast, sizeof(broadcast));
	k_msleep(3);
	zassert_equal(bank[2], 33);
	zassert_equal(fake.tx_len, 0);
	frames[6] ^= 1;
	feed(frames, 8);
	k_msleep(3);
	zassert_equal(fake.tx_len, 0);
}

ZTEST(modbus_port, test_cdc_usb_packet_sized_frame)
{
	uint8_t frame[80] = {10, 16, 0, 0, 0, 32, 64};

	for (size_t i = 0; i < 32; i++) {
		sys_put_be16((uint16_t)(i + 100), frame + 7 + i * 2);
	}
	size_t len = add_crc(frame, 71);

	configure(MB_SLAVE, USB_CDC_HW);
	zassert_ok(ModbusStart(&handler));
	feed(frame, 64);
	k_msleep(3);
	zassert_equal(fake.tx_len, 0);
	feed(frame + 64, len - 64);
	wait_tx(8);
	for (size_t i = 0; i < 32; i++) {
		zassert_equal(bank[i], i + 100);
	}
}

ZTEST(modbus_port, test_cdc_configured_response_capacity)
{
	uint16_t count = MIN((MB_BUFFER_SIZE - 5U) / 2U, 125U);
	uint8_t frame[8] = {10, 3, 0, 0};

	sys_put_be16(count, frame + 4);
	add_crc(frame, 6);
	configure(MB_SLAVE, USB_CDC_HW);
	for (size_t i = 0; i < count; i++) {
		bank[i] = (uint16_t)(0x5000 + i);
	}
	zassert_ok(ModbusStart(&handler));
	feed(frame, sizeof(frame));
	wait_tx(5U + 2U * count);
	zassert_equal(fake.tx[2], 2U * count);
	for (size_t i = 0; i < count; i++) {
		zassert_equal(sys_get_be16(fake.tx + 3U + i * 2U), bank[i]);
	}
	zassert_equal(calcCRC(fake.tx, fake.tx_len), 0);
}

ZTEST(modbus_port, test_cdc_incomplete_and_unknown_expiry)
{
	uint8_t frame[8] = {10, 6, 0, 0, 0, 42};
	uint8_t unknown[4] = {10, 0x40};

	add_crc(frame, 6);
	add_crc(unknown, 2);
	configure(MB_SLAVE, USB_CDC_HW);
	zassert_ok(ModbusStart(&handler));
	feed(frame, 3);
	wait_rtu_frame(3);
	wait_rtu_frame(0);
	zassert_equal(fake.tx_len, 0);
	zassert_equal(bank[0], 0);
	feed(frame, 8);
	wait_tx(8);
	wait_rtu_frame(0);
	zassert_mem_equal(fake.tx, frame, sizeof(frame));
	zassert_equal(bank[0], 42);
	fake.tx_len = 0;
	feed(unknown, sizeof(unknown));
	wait_rtu_frame(sizeof(unknown));
	zassert_equal(fake.tx_len, 0);
	wait_tx(5);
	zassert_equal(fake.tx[1], 0xc0);
	zassert_equal(fake.tx[2], 1);
	zassert_equal(calcCRC(fake.tx, fake.tx_len), 0);
}

ZTEST(modbus_port, test_cdc_expiry_boundary_with_delayed_worker)
{
	uint8_t frame[8] = {10, 6, 0, 0, 0, 42};

	add_crc(frame, 6);
	configure(MB_SLAVE, USB_CDC_HW);
	for (unsigned int expired = 0; expired < 2U; expired++) {
		zassert_ok(ModbusStart(&handler));
		/* Neither ingress batch can be consumed until both are queued.
		 * Just before expiry, retain the prefix; at expiry, discard it.
		 */
		k_sched_lock();
		feed(frame, 3);
		uint64_t arrival = handler._private.last_rx_us +
			(uint64_t)CONFIG_MODBUS_PORT_CDC_ASSEMBLY_MS * 1000U;

		if (expired == 0U) {
			mb_rtu_ingress(&handler, frame + 3, sizeof(frame) - 3U, arrival - 1U);
		} else {
			mb_rtu_ingress(&handler, frame, sizeof(frame), arrival);
		}
		k_sched_unlock();
		wait_tx(sizeof(frame));
		zassert_mem_equal(fake.tx, frame, sizeof(frame));
		zassert_equal(bank[0], 42);
		zassert_ok(ModbusStop(&handler));
		fake.tx_len = 0;
		bank[0] = 0;
	}
}

ZTEST(modbus_port, test_queue_prepend_exhaustion_metadata_and_completion)
{
	struct modbus_completion a, b, c;
	uint16_t values[] = {11, 22, 33};
	modbus_t q;

	configure(MB_MASTER, USB_CDC_HW);
	zassert_ok(ModbusStart(&handler));
	ModbusCompletionInit(&a);
	ModbusCompletionInit(&b);
	ModbusCompletionInit(&c);
	k_sched_lock();
	q = query(&a, &values[0], 0);
	zassert_ok(ModbusQuery(&handler, q));
	zassert_equal(ModbusQuery(&handler, q), -EBUSY);
	q.u16RegAdd = 55;
	zassert_ok(ModbusQueryInject(&handler, query(&b, &values[1], 1)));
	zassert_equal(ModbusQuery(&handler, query(&c, &values[2], 2)), -ENOSPC);
	zassert_false(atomic_get(&c.in_flight));
	k_sched_unlock();
	wait_tx(8);
	zassert_equal(fake.tx[3], 1);
	uint8_t echo[8];

	memcpy(echo, fake.tx, 8);
	feed(echo, 8);
	zassert_ok(k_sem_take(&b.sem, K_MSEC(500)));
	zassert_ok(b.result);
	wait_tx(16);
	zassert_equal(fake.tx[11], 0); /* Original metadata, not caller's mutation. */
	memcpy(echo, fake.tx + 8, 8);
	feed(echo, 8);
	zassert_ok(k_sem_take(&a.sem, K_MSEC(500)));
	zassert_ok(a.result);
	zassert_false(atomic_get(&a.in_flight));
}

static void reset_isr(const void *arg)
{
	ModbusTransportReset((modbusHandler_t *)arg);
}

ZTEST(modbus_port, test_reset_and_stop_release_all_ownership)
{
	struct modbus_completion a, b;
	uint16_t value = 7;

	configure(MB_MASTER, USB_CDC_HW);
	zassert_ok(ModbusStart(&handler));
	ModbusCompletionInit(&a);
	ModbusCompletionInit(&b);
	zassert_ok(ModbusQuery(&handler, query(&a, &value, 0)));
	wait_tx(8);
	zassert_ok(ModbusQuery(&handler, query(&b, &value, 1)));
	irq_offload(reset_isr, &handler);
	zassert_ok(k_sem_take(&a.sem, K_MSEC(500)));
	zassert_ok(k_sem_take(&b.sem, K_MSEC(500)));
	zassert_equal(a.result, -ECONNRESET);
	zassert_equal(b.result, -ECONNRESET);
	k_sched_lock();
	zassert_ok(ModbusQuery(&handler, query(&a, &value, 0)));
	k_sched_unlock();
	zassert_ok(ModbusStop(&handler));
	zassert_ok(k_sem_take(&a.sem, K_NO_WAIT));
	zassert_equal(a.result, -ECANCELED);
	zassert_equal(ModbusQuery(&handler, query(&a, &value, 0)), -ESHUTDOWN);
}

ZTEST(modbus_port, test_blocking_timeout_and_tx_backpressure)
{
	uint16_t value = 0xbeef;

	configure(MB_MASTER, USB_CDC_HW);
	zassert_ok(ModbusStart(&handler));
	fake.stalled = true;
	zassert_equal(ModbusQueryV2(&handler, query(NULL, &value, 0)), -ETIMEDOUT);
	zassert_equal(value, 0xbeef);
	zassert_equal(fake.tx_len, 0);
	zassert_false(handler._private.active_valid);
}

ZTEST(modbus_port, test_rtu_master_reply_validation)
{
	struct modbus_completion done;
	uint16_t value = 0xbeef;
	uint8_t reply[7] = {11, 3, 2, 0x12, 0x34};

	configure(MB_MASTER, USB_CDC_HW);
	zassert_ok(ModbusStart(&handler));
	ModbusCompletionInit(&done);
	modbus_t q = query(&done, &value, 0);

	q.u8fct = 3;
	zassert_ok(ModbusQuery(&handler, q));
	wait_tx(8);
	add_crc(reply, 5);
	feed(reply, 7); /* Wrong unit is ignored. */
	k_msleep(2);
	zassert_equal(k_sem_take(&done.sem, K_NO_WAIT), -EBUSY);
	zassert_equal(value, 0xbeef);
	reply[0] = 10;
	add_crc(reply, 5);
	reply[5] ^= 1;
	feed(reply, 7); /* Corrupt CRC is ignored. */
	k_msleep(2);
	zassert_equal(k_sem_take(&done.sem, K_NO_WAIT), -EBUSY);
	zassert_equal(value, 0xbeef);
	add_crc(reply, 5);
	feed(reply, 7);
	zassert_ok(k_sem_take(&done.sem, K_MSEC(500)));
	zassert_ok(done.result);
	zassert_equal(value, 0x1234);

	zassert_ok(ModbusQuery(&handler, q));
	wait_tx(16);
	uint8_t exception[5] = {10, 0x83, 2};

	add_crc(exception, 3);
	feed(exception, 5);
	zassert_ok(k_sem_take(&done.sem, K_MSEC(500)));
	zassert_equal(done.result, 2);
	zassert_equal(value, 0x1234);

	zassert_ok(ModbusQuery(&handler, q));
	wait_tx(24);
	uint8_t malformed[6] = {10, 3, 1, 0x56};

	add_crc(malformed, 4);
	feed(malformed, sizeof(malformed));
	zassert_ok(k_sem_take(&done.sem, K_MSEC(500)));
	zassert_equal(done.result, -EBADMSG);
	zassert_equal(value, 0x1234);
}

ZTEST(modbus_port, test_rtu_bounded_rx_overflow)
{
	struct modbus_completion done;
	uint16_t value = 0xbeef;
	uint8_t overflow[MB_RX_CAPACITY + 1] = {0};

	configure(MB_MASTER, USB_CDC_HW);
	zassert_ok(ModbusStart(&handler));
	ModbusCompletionInit(&done);
	zassert_ok(ModbusQuery(&handler, query(&done, &value, 0)));
	wait_tx(8);
	mb_rtu_ingress(&handler, overflow, sizeof(overflow), 1);
	zassert_ok(k_sem_take(&done.sem, K_MSEC(500)));
	zassert_equal(done.result, -ENOBUFS);
	zassert_equal(value, 0xbeef);
	zassert_false(handler._private.active_valid);
}

ZTEST(modbus_port, test_uart_actual_timing_and_gap_rejection)
{
	uint8_t frame[8] = {10, 6, 0, 0, 0, 42};

	add_crc(frame, 6);
	configure(MB_SLAVE, USART_HW);
	zassert_ok(ModbusStart(&handler));
	zassert_equal(handler._private.t15_us, 1719);
	zassert_equal(handler._private.t35_us, 4011);
	/* Inject an exact 2500-us FIFO gap, independent of QEMU kernel ticks. */
	k_sched_lock();
	feed(frame, 4);
	mb_rtu_ingress(&handler, frame + 4, 4, handler._private.last_rx_us + 2500U);
	k_sched_unlock();
	k_msleep(8);
	zassert_equal(bank[0], 0);
	zassert_equal(fake.tx_len, 0);
	feed(frame, 8);
	wait_tx(8);
	zassert_equal(bank[0], 42);
}

#ifdef CONFIG_MODBUS_PORT_TCP
static int connect_loopback(uint16_t port)
{
	int fd = zsock_socket(NET_AF_INET, NET_SOCK_STREAM, NET_IPPROTO_TCP);
	struct net_sockaddr_in address = { .sin_family = NET_AF_INET, .sin_port = sys_cpu_to_be16(port),
		.sin_addr.s_addr = sys_cpu_to_be32(0x7f000001) };

	zassert_true(fd >= 0, "socket errno %d", errno);
	zassert_ok(zsock_connect(fd, (struct net_sockaddr *)&address, sizeof(address)),
		   "connect errno %d", errno);
	return fd;
}
static void recv_exact(int fd, uint8_t *data, size_t len)
{
	size_t got = 0;

	while (got < len) {
		struct zsock_pollfd pollfd = { .fd = fd, .events = ZSOCK_POLLIN };

		zassert_equal(zsock_poll(&pollfd, 1, 1000), 1);
		ssize_t n = zsock_recv(fd, data + got, len - got, 0);

		zassert_true(n > 0, "recv %d errno %d", (int)n, errno);
		got += n;
	}
}

static int make_listener(uint16_t port)
{
	int fd = zsock_socket(NET_AF_INET, NET_SOCK_STREAM, NET_IPPROTO_TCP);
	struct net_sockaddr_in address = { .sin_family = NET_AF_INET,
		.sin_port = sys_cpu_to_be16(port), .sin_addr.s_addr = sys_cpu_to_be32(0x7f000001) };

	zassert_true(fd >= 0);
	zassert_ok(zsock_bind(fd, (struct net_sockaddr *)&address, sizeof(address)));
	zassert_ok(zsock_listen(fd, 4));
	return fd;
}
static int accept_one(int listener)
{
	struct zsock_pollfd pollfd = { .fd = listener, .events = ZSOCK_POLLIN };

	zassert_equal(zsock_poll(&pollfd, 1, 1000), 1);
	int fd = zsock_accept(listener, NULL, NULL);

	zassert_true(fd >= 0);
	return fd;
}
static void await_result(struct modbus_completion *done, int expected)
{
	zassert_ok(k_sem_take(&done->sem, K_MSEC(1000)));
	zassert_equal(done->result, expected, "result %d expected %d", done->result, expected);
	zassert_false(atomic_get(&done->in_flight));
}

ZTEST(modbus_port, test_tcp_master_matching_endpoint_change_and_disconnect)
{
	struct modbus_completion done;
	uint16_t value = 0;
	uint8_t request[12];
	uint8_t response[11] = {0, 0, 0, 0, 0, 5, 10, 3, 2, 0x12, 0x34};
	int listeners[] = {make_listener(15021), make_listener(15022)};
	int peers[2];

	configure(MB_MASTER, TCP_HW);
	zassert_ok(ModbusStart(&handler));
	ModbusCompletionInit(&done);
	modbus_t q = query(&done, &value, 0);

	q.u8fct = 3;
	q.xIpAddress = sys_cpu_to_be32(0x7f000001);
	q.u16Port = 15021;
	zassert_ok(ModbusQuery(&handler, q));
	peers[0] = accept_one(listeners[0]);
	recv_exact(peers[0], request, sizeof(request));
	memcpy(response, request, 2);
	zassert_equal(zsock_send(peers[0], response, 5, 0), 5);
	k_msleep(2);
	zassert_equal(zsock_send(peers[0], response + 5, 6, 0), 6);
	await_result(&done, 0);
	zassert_equal(value, 0x1234);

	/* A changed endpoint in the same u8clientID must close and reconnect. */
	q.u16Port = 15022;
	zassert_ok(ModbusQuery(&handler, q));
	peers[1] = accept_one(listeners[1]);
	recv_exact(peers[1], request, sizeof(request));
	uint8_t exception[9] = {request[0], request[1], 0, 0, 0, 3, 10, 0x83, 2};

	zassert_equal(zsock_send(peers[1], exception, sizeof(exception), 0), sizeof(exception));
	await_result(&done, 2);
	zassert_equal(value, 0x1234);
	zsock_close(peers[0]);

	zassert_ok(ModbusQuery(&handler, q));
	recv_exact(peers[1], request, sizeof(request));
	memcpy(response, request, 2);
	response[1] ^= 1; /* Wrong transaction must never mutate caller memory. */
	zassert_equal(zsock_send(peers[1], response, sizeof(response), 0), sizeof(response));
	await_result(&done, -EBADMSG);
	zassert_equal(value, 0x1234);
	zsock_close(peers[1]);

	zassert_ok(ModbusQuery(&handler, q));
	peers[1] = accept_one(listeners[1]);
	recv_exact(peers[1], request, sizeof(request));
	memcpy(response, request, 2);
	response[6] = 11; /* Wrong unit, even with matching transaction. */
	zassert_equal(zsock_send(peers[1], response, sizeof(response), 0), sizeof(response));
	await_result(&done, -EBADMSG);
	zassert_equal(value, 0x1234);
	zsock_close(peers[1]);

	zassert_ok(ModbusQuery(&handler, q));
	peers[1] = accept_one(listeners[1]);
	recv_exact(peers[1], request, sizeof(request));
	zsock_close(peers[1]);
	await_result(&done, -ECONNRESET);
	zassert_ok(ModbusQuery(&handler, q));
	peers[1] = accept_one(listeners[1]);
	recv_exact(peers[1], request, sizeof(request));
	await_result(&done, -ETIMEDOUT);
	zassert_equal(value, 0x1234);
	zsock_close(peers[1]);
	zsock_close(listeners[0]);
	zsock_close(listeners[1]);
}

ZTEST(modbus_port, test_tcp_mbap_limits)
{
	uint8_t header[] = {0, 1, 0, 0, 0, 6};

	for (size_t i = 0; i < 6; i++) {
		zassert_equal(mb_tcp_adu_length(header, i), 0);
	}
	zassert_equal(mb_tcp_adu_length(header, 6), 12);
	header[2] = 1;
	zassert_equal(mb_tcp_adu_length(header, 6), -EBADMSG);
	header[2] = 0;
	header[3] = 1;
	zassert_equal(mb_tcp_adu_length(header, 6), -EBADMSG);
	header[3] = 0;
	header[5] = 1;
	zassert_equal(mb_tcp_adu_length(header, 6), -EBADMSG);
	sys_put_be16(MB_TCP_BUFFER_SIZE - 6, header + 4);
	zassert_equal(mb_tcp_adu_length(header, 6), MB_TCP_BUFFER_SIZE);
	sys_put_be16(MB_TCP_BUFFER_SIZE - 5, header + 4);
	zassert_equal(mb_tcp_adu_length(header, 6),
		      MB_TCP_BUFFER_SIZE == 260U ? -EBADMSG : -EMSGSIZE);
}

ZTEST(modbus_port, test_tcp_configured_capacity_both_roles)
{
	uint16_t words[MIN((MB_TCP_BUFFER_SIZE - 9U) / 2U, 125U)];
	uint16_t count = ARRAY_SIZE(words);

	configure(MB_SLAVE, TCP_HW);
	handler.uTcpPort = 15025;
	for (size_t i = 0; i < ARRAY_SIZE(bank); i++) {
		bank[i] = (uint16_t)(0x5000U + i);
	}
	memset(&second, 0, sizeof(second));
	second.uModbusType = MB_MASTER;
	second.xTypeHW = TCP_HW;
	second.u16timeOut = 1000;
	zassert_ok(ModbusInit(&second));
	zassert_ok(ModbusStart(&handler));
	zassert_ok(ModbusStart(&second));
	modbus_t q = {
		.u8id = 10, .u8fct = 16, .u16RegAdd = 0, .u16CoilsNo = 32,
		.u16reg = words, .u16regCapacity = ARRAY_SIZE(words),
		.xIpAddress = sys_cpu_to_be32(0x7f000001), .u16Port = handler.uTcpPort,
	};

	/* A valid 77-byte write request exceeds one full-speed USB packet. */
	for (size_t i = 0; i < 32U; i++) {
		words[i] = (uint16_t)(0xa000U + i);
	}
	zassert_ok(ModbusQueryV2(&second, q));
	zassert_mem_equal(words, bank, 32U * sizeof(words[0]));
	memset(words, 0, sizeof(words));
	q.u8fct = 3;
	q.u16CoilsNo = count;
	/* MBAP, unit, function and byte count consume nine ADU bytes. */
	zassert_ok(ModbusQueryV2(&second, q));
	zassert_mem_equal(words, bank, count * sizeof(words[0]));
	zassert_ok(ModbusStop(&second));
	zassert_ok(ModbusStop(&handler));
}

ZTEST(modbus_port, test_tcp_real_stream_splits_coalescing_and_clients)
{
	uint8_t request[24] = {0x12, 0x34, 0, 0, 0, 6, 10, 6, 0, 0, 0, 42};
	uint8_t reply[24];
	int clients[MB_TCP_CONNECTIONS];

	configure(MB_SLAVE, TCP_HW);
	zassert_ok(ModbusStart(&handler));
	for (size_t i = 0; i < ARRAY_SIZE(clients); i++) {
		clients[i] = connect_loopback(handler.uTcpPort);
	}
	for (size_t split = 1; split < 12; split++) {
		zassert_equal(zsock_send(clients[0], request, split, 0), split);
		k_msleep(2);
		zassert_equal(zsock_send(clients[0], request + split, 12 - split, 0), 12 - split);
		recv_exact(clients[0], reply, 12);
		zassert_mem_equal(reply, request, 12);
	}
	memcpy(request + 12, request, 12);
	request[13]++;
	for (size_t i = 0; i < ARRAY_SIZE(clients); i++) {
		zassert_equal(zsock_send(clients[i], request, sizeof(request), 0), sizeof(request));
	}
	for (size_t i = 0; i < ARRAY_SIZE(clients); i++) {
		recv_exact(clients[i], reply, sizeof(reply));
		zassert_mem_equal(reply, request, sizeof(reply));
		zsock_close(clients[i]);
	}
	zassert_equal(bank[0], 42);
}
ZTEST(modbus_port, test_tcp_pool_idle_invalid_pid_and_reconnect)
{
	uint8_t request[12] = {0, 1, 0, 0, 0, 6, 10, 6, 0, 0, 0, 42};
	uint8_t reply[12];
	int clients[MB_TCP_CONNECTIONS];

	configure(MB_SLAVE, TCP_HW);
	handler.uTcpPort = 15023;
	handler.tcp_idle_ms = 500;
	zassert_ok(ModbusStart(&handler));
	for (size_t i = 0; i < ARRAY_SIZE(clients); i++) {
		clients[i] = connect_loopback(handler.uTcpPort);
		zassert_equal(zsock_send(clients[i], request, sizeof(request), 0), sizeof(request));
		recv_exact(clients[i], reply, sizeof(reply));
	}
	int extra = zsock_socket(NET_AF_INET, NET_SOCK_STREAM, NET_IPPROTO_TCP);
	struct net_sockaddr_in address = { .sin_family = NET_AF_INET,
		.sin_port = sys_cpu_to_be16(handler.uTcpPort),
		.sin_addr.s_addr = sys_cpu_to_be32(0x7f000001) };
	struct zsock_pollfd pollfd = {.fd = extra, .events = ZSOCK_POLLIN};

	zassert_true(extra >= 0);
	int connected = zsock_connect(extra, (struct net_sockaddr *)&address, sizeof(address));

	/* Immediate close may race connect's completion in the loopback stack. */
	if (connected == 0) {
		zassert_equal(zsock_poll(&pollfd, 1, 1000), 1);
		zassert_equal(zsock_recv(extra, reply, sizeof(reply), 0), 0);
	} else {
		zassert_true(errno == ECONNREFUSED || errno == ECONNRESET);
	}
	zsock_close(extra);
	for (size_t i = 0; i < ARRAY_SIZE(clients); i++) {
		pollfd.fd = clients[i];
		zassert_equal(zsock_poll(&pollfd, 1, 1000), 1);
		zassert_equal(zsock_recv(clients[i], reply, sizeof(reply), 0), 0);
		zsock_close(clients[i]);
	}
	int fd = connect_loopback(handler.uTcpPort);

	request[2] = 1; /* Either nonzero PID byte is invalid. */
	zassert_equal(zsock_send(fd, request, sizeof(request), 0), sizeof(request));
	pollfd.fd = fd;
	zassert_equal(zsock_poll(&pollfd, 1, 1000), 1);
	zassert_equal(zsock_recv(fd, reply, sizeof(reply), 0), 0);
	zsock_close(fd);
	fd = connect_loopback(handler.uTcpPort);
	request[2] = 0;
	request[3] = 1;
	zassert_equal(zsock_send(fd, request, sizeof(request), 0), sizeof(request));
	pollfd.fd = fd;
	zassert_equal(zsock_poll(&pollfd, 1, 1000), 1);
	zassert_equal(zsock_recv(fd, reply, sizeof(reply), 0), 0);
	zsock_close(fd);
}

ZTEST(modbus_port, test_two_handlers_shared_bank)
{
	static struct k_mutex lock;
	uint8_t tcp[12] = {0, 1, 0, 0, 0, 6, 10, 6, 0, 0, 0, 77};
	uint8_t rtu[8] = {10, 6, 0, 1, 0, 88};
	uint8_t response[12];

	k_mutex_init(&lock);
	configure(MB_SLAVE, TCP_HW);
	handler.uTcpPort = 15024;
	handler.memory_lock = &lock;
	memset(&second, 0, sizeof(second));
	second.uModbusType = MB_SLAVE;
	second.xTypeHW = USB_CDC_HW;
	second.port = DEVICE_GET(test_uart);
	second.u8id = 10;
	second.memory = handler.memory;
	second.memory_lock = &lock;
	zassert_ok(ModbusInit(&second));
	zassert_ok(ModbusStart(&handler));
	zassert_ok(ModbusStartCDC(&second));
	int fd = connect_loopback(handler.uTcpPort);

	add_crc(rtu, 6);
	k_mutex_lock(&lock, K_FOREVER);
	zassert_equal(zsock_send(fd, tcp, sizeof(tcp), 0), sizeof(tcp));
	feed(rtu, sizeof(rtu));
	k_mutex_unlock(&lock);
	recv_exact(fd, response, sizeof(response));
	wait_tx(8);
	zassert_equal(bank[0], 77);
	zassert_equal(bank[1], 88);
	zassert_mem_equal(response, tcp, sizeof(tcp));
	zassert_mem_equal(fake.tx, rtu, sizeof(rtu));
	zsock_close(fd);
	zassert_ok(ModbusStop(&second));
	zassert_ok(ModbusStop(&handler));
}
#endif

ZTEST_SUITE(modbus_port, NULL, NULL, before, after, NULL);
