/* SPDX-License-Identifier: Apache-2.0 */
#include <zephyr/ztest.h>
#include <zephyr/irq_offload.h>
#include <class/usbd_cdc_acm.c>

/* No copy of driver logic: class API, UART API and all work handlers above are
 * the actual patched SDK source. Mock only USB ownership and completions. */
UDC_BUF_POOL_DEFINE(test_tx_pool, 4, 64, sizeof(struct udc_buf_info), NULL);
UDC_BUF_POOL_DEFINE(test_rx_pool, 4, 64, sizeof(struct udc_buf_info), NULL);
UDC_BUF_POOL_DEFINE(test_notif_pool, 2, 16, sizeof(struct udc_buf_info), NULL);
K_SEM_DEFINE(submitting, 0, 1);
K_SEM_DEFINE(release_submit, 0, 1);
K_SEM_DEFINE(notification_retired, 0, 1);
K_SEM_DEFINE(callback_entered, 0, 1);
K_SEM_DEFINE(release_callback, 0, 1);
K_THREAD_STACK_DEFINE(sender_stack, 1536);
static struct k_thread sender_thread;
static int sender_result;
static bool inline_notification;
static bool pause_notification;
K_FIFO_DEFINE(rx_fifo);
K_FIFO_DEFINE(usb_pending);
K_FIFO_DEFINE(usb_retired);
static struct cdc_acm_uart_data data;
static struct usbd_context context;
static struct usbd_class_data class_data;
static struct usbd_cdc_acm_desc desc = {
	.if0_int_ep.bEndpointAddress = 0x81,
	.if1_in_ep.bEndpointAddress = 0x82,
	.if1_out_ep.bEndpointAddress = 0x01,
};
static const struct cdc_acm_uart_config config = {
	.c_data = &class_data, .desc = &desc,
};
static const struct device uart = {
	.name = "mock_cdc", .data = &data, .config = &config,
	.api = &cdc_acm_uart_api,
};
static bool hold_completions;
static bool fail_enqueue;
static bool fail_dequeue;
static bool close_in_enqueue;
static bool initialized;
static unsigned int boundaries;
static unsigned int irq_calls;
static unsigned int submitted_payloads;
static uint8_t last_payload[64];
static size_t last_length;

static void control(bool dtr);

static void complete(struct net_buf *buf, int err)
{
	zassert_ok(usbd_cdc_acm_api.request(&class_data, buf, err));
}

int usbd_ep_enqueue(const struct usbd_class_data *const c, struct net_buf *const buf)
{
	zassert_false(k_is_in_isr(), "UDC enqueue in ISR");
	zassert_equal(c, &class_data);
	if (fail_enqueue) {
		return -EIO;
	}
	if (udc_get_buf_info(buf)->ep == 0x82 && buf->len != 0) {
		submitted_payloads++;
		last_length = buf->len;
		memcpy(last_payload, buf->data, buf->len);
	}
	if (udc_get_buf_info(buf)->ep == 0x81 && inline_notification) {
		control(false);
		control(true);
		complete(buf, 0);
		return 0;
	}
	k_fifo_put(&usb_pending, buf);
	if (udc_get_buf_info(buf)->ep == 0x81 && pause_notification) {
		k_sem_give(&submitting);
		zassert_ok(k_sem_take(&release_submit, K_SECONDS(2)));
	}
	if (close_in_enqueue) {
		close_in_enqueue = false;
		usbd_cdc_acm_api.disable(&class_data);
		usbd_cdc_acm_api.enable(&class_data);
	}
	return 0;
}

int usbd_ep_dequeue(struct usbd_context *ctx, const uint8_t ep)
{
	struct net_buf *buf;
	struct k_fifo keep;
	k_fifo_init(&keep);

	zassert_false(k_is_in_isr(), "UDC dequeue in ISR");
	zassert_equal(ctx, &context);
	if (fail_dequeue) {
		return -EIO;
	}
	while ((buf = k_fifo_get(&usb_pending, K_NO_WAIT)) != NULL) {
		if (udc_get_buf_info(buf)->ep != ep) {
			k_fifo_put(&keep, buf);
		} else if (hold_completions) {
			k_fifo_put(&usb_retired, buf);
		} else {
			complete(buf, -ECONNABORTED);
		}
	}
	while ((buf = k_fifo_get(&keep, K_NO_WAIT)) != NULL) {
		k_fifo_put(&usb_pending, buf);
	}
	if (ep == 0x81 && pause_notification) {
		k_sem_give(&notification_retired);
	}
	return 0;
}

int usbd_ep_buf_free(struct usbd_context *const ctx, struct net_buf *buf)
{
	ARG_UNUSED(ctx);
	net_buf_unref(buf);
	return 0;
}
struct net_buf *usbd_ep_buf_alloc(const struct usbd_class_data *const c,
				const uint8_t ep, const size_t size)
{
	zassert_equal(c, &class_data);
	zassert_equal(ep, 0x81);
	zassert_true(size <= 16);
	struct net_buf *buf = net_buf_alloc(&test_notif_pool, K_NO_WAIT);
	if (buf != NULL) {
		udc_get_buf_info(buf)->ep = ep;
	}
	return buf;
}
struct net_buf *usbd_ep_ctrl_data_in_alloc(const struct usbd_context *const ctx,
					 const size_t size)
{
	ARG_UNUSED(ctx); ARG_UNUSED(size);
	return NULL;
}
enum usbd_speed usbd_bus_speed(const struct usbd_context *const ctx)
{
	ARG_UNUSED(ctx);
	return USBD_SPEED_FS;
}
int usbd_add_descriptor(struct usbd_context *const ctx, struct usbd_desc_node *const node)
{
	ARG_UNUSED(ctx); ARG_UNUSED(node);
	return 0;
}
uint8_t usbd_str_desc_get_idx(const struct usbd_desc_node *const node)
{
	ARG_UNUSED(node);
	return 0;
}
void usbd_msg_pub_device(struct usbd_context *const ctx, const enum usbd_msg_type type,
			 const struct device *const dev)
{
	/* Deliberately do not deliver asynchronous application messages. */
	ARG_UNUSED(ctx); ARG_UNUSED(type); ARG_UNUSED(dev);
}

static void drain(void)
{
#if CONFIG_USBD_CDC_ACM_WORKQUEUE
	k_work_queue_drain(&cdc_acm_work_q, false);
#else
	k_work_queue_drain(&k_sys_work_q, false);
#endif
}

static void session_cb(const struct device *dev, void *arg)
{
	zassert_equal(dev, &uart);
	zassert_equal(arg, &boundaries);
	zassert_true(cdc_acm_session_is_closed(&data));
	zassert_true(k_fifo_is_empty(&rx_fifo));
	zassert_true(data.tx_fifo.current == NULL || data.tx_fifo.current->len == 0);
	boundaries++;
}

static void irq_cb(const struct device *dev, void *arg)
{
	ARG_UNUSED(dev); ARG_UNUSED(arg);
	irq_calls++;
}

static void control(bool dtr)
{
	struct usb_setup_packet setup = {
		.bRequest = SET_CONTROL_LINE_STATE,
		.wValue = dtr ? SET_CONTROL_LINE_STATE_DTR : 0,
	};
	zassert_ok(usbd_cdc_acm_api.control_to_dev(&class_data, &setup, NULL));
}

static void finish_retired(int err)
{
	struct net_buf *buf;
	while ((buf = k_fifo_get(&usb_retired, K_NO_WAIT)) != NULL) {
		if (udc_get_buf_info(buf)->ep == 0x01 && err == 0) {
			net_buf_add_mem(buf, "stale", 5);
		}
		complete(buf, err);
	}
	drain();
}

static struct net_buf *take_pending(uint8_t ep)
{
	struct k_fifo keep;
	k_fifo_init(&keep);
	struct net_buf *found = NULL;
	struct net_buf *buf;
	while ((buf = k_fifo_get(&usb_pending, K_NO_WAIT)) != NULL) {
		if (found == NULL && udc_get_buf_info(buf)->ep == ep) {
			found = buf;
		} else {
			k_fifo_put(&keep, buf);
		}
	}
	while ((buf = k_fifo_get(&keep, K_NO_WAIT)) != NULL) {
		k_fifo_put(&usb_pending, buf);
	}
	zassert_not_null(found, "No pending ep %02x", ep);
	return found;
}

static void before(void *fixture)
{
	ARG_UNUSED(fixture);
	if (initialized) {
		hold_completions = false;
		fail_dequeue = false;
		fail_enqueue = false;
		close_in_enqueue = false;
		usbd_cdc_acm_api.disable(&class_data);
		drain();
		finish_retired(-ECONNABORTED);
		k_work_cancel_delayable(&data.tx_fifo_work);
		drain();
		zassert_equal(data.tx_fifo.enqueued, 0);
		zassert_equal(data.rx_enqueued, 0);
		zassert_equal(data.notif_enqueued, 0);
		net_buf_unref(data.tx_fifo.current);
	}
	memset(&data, 0, sizeof(data));
	data.dev = &uart;
	data.line_coding = (struct cdc_acm_line_coding)CDC_ACM_DEFAULT_LINECODING;
	data.tx_fifo.pool = &test_tx_pool;
	data.rx_fifo.pool = &test_rx_pool;
	data.rx_fifo.bufs = &rx_fifo;
	class_data.uds_ctx = &context;
	class_data.priv = (void *)&uart;
	k_sem_init(&data.notif_sem, 0, 1);
	inline_notification = false;
	pause_notification = false;
	k_sem_reset(&notification_retired);
	k_sem_reset(&submitting);
	k_sem_reset(&release_submit);
	k_sem_reset(&callback_entered);
	k_sem_reset(&release_callback);
	boundaries = irq_calls = submitted_payloads = 0;
	last_length = 0;
	zassert_ok(usbd_cdc_acm_preinit(&uart));
	zassert_ok(usbd_cdc_acm_set_session_cb(&uart, session_cb, &boundaries));
	cdc_acm_irq_callback_set(&uart, irq_cb, NULL);
	usbd_cdc_acm_api.enable(&class_data);
	drain();
	initialized = true;
	zassert_false(cdc_acm_session_is_closed(&data));
	zassert_equal(boundaries, 1);
}

ZTEST(cdc, test_no_terminal_boot)
{
	zassert_false(data.line_state_dtr);
	zassert_false(cdc_acm_session_is_closed(&data));
	zassert_equal(data.rx_enqueued, 4);
	zassert_equal(data.tx_fifo.enqueued, 1);
}

ZTEST(cdc, test_retained_and_inflight_buffers_are_purged)
{
	struct net_buf *buf = take_pending(0x01);
	net_buf_add_mem(buf, "old", 3);
	complete(buf, 0);
	drain();
	cdc_acm_poll_out(&uart, 'X');
	zassert_equal(data.tx_fifo.current->len, 1);
	hold_completions = true;
	control(false);
	drain();
	zassert_true(cdc_acm_session_is_closed(&data));
	zassert_true(k_fifo_is_empty(&rx_fifo));
	zassert_equal(data.tx_fifo.current->len, 0);
	zassert_equal(boundaries, 2);
	control(true);
	drain();
	zassert_true(cdc_acm_session_is_closed(&data), "must await UDC ownership return");
	finish_retired(0);
	zassert_false(cdc_acm_session_is_closed(&data));
	zassert_true(k_fifo_is_empty(&rx_fifo), "late successful RX crossed session");
	zassert_equal(submitted_payloads, 0);
}

ZTEST(cdc, test_rapid_dtr_reopen_cannot_skip_boundary)
{
	hold_completions = true;
	control(true);
	control(false);
	control(true);
	drain();
	zassert_equal(boundaries, 2);
	zassert_true(cdc_acm_session_is_closed(&data));
	finish_retired(-ECONNABORTED);
	zassert_false(cdc_acm_session_is_closed(&data));
}

ZTEST(cdc, test_disable_enable_delayed_completions)
{
	hold_completions = true;
	cdc_acm_poll_out(&uart, 'D');
	usbd_cdc_acm_api.disable(&class_data);
	usbd_cdc_acm_api.enable(&class_data);
	drain();
	zassert_true(cdc_acm_session_is_closed(&data));
	finish_retired(-ECONNABORTED);
	zassert_false(cdc_acm_session_is_closed(&data));
	zassert_equal(submitted_payloads, 0);
}

ZTEST(cdc, test_close_inside_enqueue_is_fenced)
{
	control(false);
	drain();
	close_in_enqueue = true;
	control(true);
	drain();
	zassert_false(close_in_enqueue);
	zassert_false(cdc_acm_session_is_closed(&data));
	zassert_equal(data.rx_enqueued, 4);
	zassert_equal(data.tx_fifo.enqueued, 1);
	zassert_equal(submitted_payloads, 0);
}

static void close_from_callback(const struct device *dev, void *arg)
{
	ARG_UNUSED(dev); ARG_UNUSED(arg);
	control(false);
	control(true);
	cdc_acm_irq_tx_disable(&uart);
}

ZTEST(cdc, test_close_from_uart_callback_no_self_deadlock)
{
	cdc_acm_irq_callback_set(&uart, close_from_callback, NULL);
	cdc_acm_irq_tx_enable(&uart);
	drain();
	zassert_equal(boundaries, 2);
	zassert_false(cdc_acm_session_is_closed(&data));
}

ZTEST(cdc, test_closed_uart_admission_and_poll_flow_control)
{
	control(false);
	drain();
	data.flow_ctrl = true;
	cdc_acm_poll_out(&uart, 'X');
	unsigned char byte;
	zassert_equal(cdc_acm_poll_in(&uart, &byte), -1);
	zassert_equal(cdc_acm_tx_fifo_space_get(&data), 0);
	unsigned int previous = irq_calls;
	cdc_acm_irq_tx_enable(&uart);
	cdc_acm_irq_rx_enable(&uart);
	drain();
	zassert_equal(irq_calls, previous);
	zassert_equal(data.tx_fifo.current->len, 0);
}

static void fill_cb(const struct device *dev, void *arg)
{
	uint8_t payload[64];
	struct k_spinlock lock = {};
	ARG_UNUSED(arg);
	memset(payload, 0xa5, sizeof(payload));
	k_spinlock_key_t key = k_spin_lock(&lock);
	zassert_equal(cdc_acm_fifo_fill(dev, payload, sizeof(payload)), sizeof(payload));
	/* Would be visible immediately if fifo_fill called the UDC under our lock. */
	zassert_equal(submitted_payloads, 0);
	k_spin_unlock(&lock, key);
	cdc_acm_irq_tx_disable(dev);
}

ZTEST(cdc, test_fifo_fill_defers_udc_outside_callers_spinlock)
{
	data.echo_mitigated = true;
	cdc_acm_irq_callback_set(&uart, fill_cb, NULL);
	cdc_acm_irq_tx_enable(&uart);
	drain();
	zassert_equal(submitted_payloads, 1);
	zassert_equal(last_length, 64);
	for (size_t i = 0; i < last_length; ++i) {
		zassert_equal(last_payload[i], 0xa5);
	}
}

struct stream_producer {
	uint8_t bytes[256];
	size_t length;
	size_t offset;
};

static void stream_irq(const struct device *dev, void *arg)
{
	struct stream_producer *stream = arg;
	int written = uart_fifo_fill(dev, stream->bytes + stream->offset,
				    stream->length - stream->offset);

	zassert_true(written >= 0);
	stream->offset += written;
	uart_irq_tx_disable(dev);
}

ZTEST(cdc, test_inflight_payload_success_after_reopen_request)
{
	data.echo_mitigated = true;
	cdc_acm_irq_callback_set(&uart, fill_cb, NULL);
	cdc_acm_irq_tx_enable(&uart);
	drain();
	struct net_buf *zlp = take_pending(0x82);
	struct net_buf *payload = take_pending(0x82);

	zassert_equal(zlp->len, 0);
	zassert_equal(payload->len, 64);
	/* These requests have left the UDC queue, but their completion events
	 * have not yet reached the class. Dequeue cannot recover them.
	 */
	control(false);
	control(true);
	drain();
	complete(zlp, 0);
	drain();
	zassert_true(cdc_acm_session_is_closed(&data));
	complete(payload, 0);
	drain();
	zassert_false(cdc_acm_session_is_closed(&data));
	zassert_equal(data.tx_fifo.current->len, 0);

	struct stream_producer fresh = {.bytes = {'n', 'e', 'w'}, .length = 3};
	data.echo_mitigated = true;
	complete(take_pending(0x82), 0);
	drain();
	cdc_acm_irq_callback_set(&uart, stream_irq, &fresh);
	uart_irq_tx_enable(&uart);
	drain();
	zassert_equal(fresh.offset, 3);
	zassert_equal(last_length, 3);
	zassert_mem_equal(last_payload, "new", 3);
}

ZTEST(cdc, test_multi_packet_fifo_streams)
{
	struct stream_producer stream;
	uint8_t received[sizeof(stream.bytes)];

	data.echo_mitigated = true;
	complete(take_pending(0x82), 0);
	drain();
	for (size_t length = 128; length <= sizeof(stream.bytes); length *= 2) {
		stream.length = length;
		stream.offset = 0;
		size_t received_length = 0;

		for (size_t i = 0; i < length; ++i) {
			stream.bytes[i] = (uint8_t)(i ^ length);
		}
		cdc_acm_irq_callback_set(&uart, stream_irq, &stream);
		while (stream.offset < length) {
			uart_irq_tx_enable(&uart);
			drain();
			while (data.tx_fifo.enqueued != 0) {
				struct net_buf *buf = take_pending(0x82);

				zassert_true(received_length + buf->len <= sizeof(received));
				memcpy(received + received_length, buf->data, buf->len);
				received_length += buf->len;
				complete(buf, 0);
				drain();
			}
		}
		zassert_equal(received_length, length);
		zassert_mem_equal(received, stream.bytes, length);
	}
}

static void partial_read_irq(const struct device *dev, void *arg)
{
	uint8_t prefix[2];
	ARG_UNUSED(arg);
	zassert_equal(uart_fifo_read(dev, prefix, sizeof(prefix)), sizeof(prefix));
	zassert_mem_equal(prefix, "ol", sizeof(prefix));
	uart_irq_rx_disable(dev);
}

ZTEST(cdc, test_partially_consumed_rx_is_purged)
{
	cdc_acm_irq_callback_set(&uart, partial_read_irq, NULL);
	struct net_buf *buf = take_pending(0x01);

	net_buf_add_mem(buf, "oldXYZ", 6);
	complete(buf, 0);
	cdc_acm_irq_rx_enable(&uart);
	drain();
	buf = k_fifo_peek_head(&rx_fifo);
	zassert_not_null(buf);
	zassert_equal(buf->len, 4);
	control(false);
	control(true);
	drain();
	zassert_true(k_fifo_is_empty(&rx_fifo));
	zassert_false(cdc_acm_session_is_closed(&data));
}

ZTEST(cdc, test_polling_without_irq_callback_recovers)
{
	cdc_acm_irq_callback_set(&uart, NULL, NULL);
	control(false);
	control(true);
	drain();
	struct net_buf *buf = take_pending(0x01);
	unsigned char byte;

	net_buf_add_mem(buf, "P", 1);
	complete(buf, 0);
	zassert_ok(uart_poll_in(&uart, &byte));
	zassert_equal(byte, 'P');
	zassert_equal(uart_poll_in(&uart, &byte), -1);
	drain();
	zassert_equal(data.rx_enqueued, 4);
}

ZTEST(cdc, test_dequeue_failure_is_fail_closed)
{
	fail_dequeue = true;
	control(false);
	control(true);
	drain();
	zassert_true(cdc_acm_session_is_closed(&data));
	zassert_equal(submitted_payloads, 0);
	fail_dequeue = false;
	control(false);
	control(true);
	drain();
	zassert_false(cdc_acm_session_is_closed(&data));
}

ZTEST(cdc, test_enqueue_failures_preserve_accounting)
{
	control(false);
	drain();
	fail_enqueue = true;
	control(true);
	drain();
	zassert_equal(data.rx_enqueued, 0);
	zassert_equal(data.tx_fifo.enqueued, 0);
	zassert_not_null(data.tx_fifo.current);
}

static void close_isr(const void *arg)
{
	ARG_UNUSED(arg);
	usbd_cdc_acm_api.disable(&class_data);
}

ZTEST(cdc, test_disable_from_isr_only_schedules_cleanup)
{
	irq_offload(close_isr, NULL);
	drain();
	zassert_true(cdc_acm_session_is_closed(&data));
	zassert_equal(data.rx_enqueued, 0);
	zassert_equal(data.tx_fifo.enqueued, 0);
}

ZTEST(cdc, test_repeated_reconnect_no_pool_leaks)
{
	for (unsigned int i = 0; i < 40; ++i) {
		hold_completions = true;
		control(false);
		control(true);
		drain();
		finish_retired(i % 2 ? 0 : -ECONNABORTED);
		zassert_false(cdc_acm_session_is_closed(&data));
		zassert_equal(data.rx_enqueued, 4);
		zassert_equal(data.tx_fifo.enqueued, 1);
		zassert_not_null(data.tx_fifo.current);
		zassert_true(k_fifo_is_empty(&rx_fifo));
	}
}

ZTEST(cdc, test_notification_completion_before_wait_is_not_lost)
{
	inline_notification = true;
	zassert_equal(cdc_acm_send_notification(&uart, 1), -ECANCELED);
	drain();
	zassert_false(cdc_acm_session_is_closed(&data));
	zassert_equal(data.notif_enqueued, 0);
	zassert_false(data.notif_busy);
}

static void send_notification(void *a, void *b, void *c)
{
	ARG_UNUSED(a); ARG_UNUSED(b); ARG_UNUSED(c);
	sender_result = cdc_acm_send_notification(&uart, 1);
}

ZTEST(cdc, test_notification_submitting_during_close)
{
	pause_notification = true;
	hold_completions = true;
	k_thread_create(&sender_thread, sender_stack, K_THREAD_STACK_SIZEOF(sender_stack),
			send_notification, NULL, NULL, NULL, 5, 0, K_NO_WAIT);
	zassert_ok(k_sem_take(&submitting, K_SECONDS(2)));
	control(false);
	control(true);
	drain();
	zassert_true(cdc_acm_session_is_closed(&data));
	zassert_equal(data.notif_submitting, 1);
	/* A concurrent notification is rejected instead of sharing completion. */
	zassert_equal(cdc_acm_send_notification(&uart, 2), -EACCES);
	k_sem_give(&release_submit);
	/* Sender resubmits cleanup when the UDC call returns. */
	zassert_ok(k_sem_take(&notification_retired, K_SECONDS(2)));
	drain();
	zassert_equal(data.notif_submitting, 0);
	finish_retired(-ECONNABORTED);
	zassert_ok(k_thread_join(&sender_thread, K_SECONDS(2)));
	zassert_equal(sender_result, -ECANCELED);
	zassert_false(cdc_acm_session_is_closed(&data));
}

static void paused_irq(const struct device *dev, void *arg)
{
	ARG_UNUSED(arg);
	uint8_t bytes[16];
	k_sem_give(&callback_entered);
	zassert_ok(k_sem_take(&release_callback, K_SECONDS(2)));
	zassert_equal(cdc_acm_fifo_read(dev, bytes, sizeof(bytes)), 0);
	zassert_equal(cdc_acm_fifo_fill(dev, (const uint8_t *)"old", 3), 0);
	cdc_acm_irq_tx_disable(dev);
}

ZTEST(cdc, test_close_races_running_callback_and_successful_rx)
{
	cdc_acm_irq_callback_set(&uart, paused_irq, NULL);
	cdc_acm_irq_tx_enable(&uart);
	zassert_ok(k_sem_take(&callback_entered, K_SECONDS(2)));
	control(false);
	control(true);
	struct net_buf *buf = take_pending(0x01);
	net_buf_add_mem(buf, "old", 3);
	complete(buf, 0);
	k_sem_give(&release_callback);
	drain();
	zassert_false(cdc_acm_session_is_closed(&data));
	zassert_true(k_fifo_is_empty(&rx_fifo));
	zassert_equal(submitted_payloads, 0);
}

static void read_irq(const struct device *dev, void *arg)
{
	uint8_t bytes[8];
	int *count = arg;
	*count = cdc_acm_fifo_read(dev, bytes, sizeof(bytes));
	zassert_equal(*count, 3);
	zassert_mem_equal(bytes, "new", 3);
	cdc_acm_irq_rx_disable(dev);
}

ZTEST(cdc, test_new_session_rx_uses_real_uart_fifo)
{
	control(false);
	control(true);
	drain();
	int count = 0;
	cdc_acm_irq_callback_set(&uart, read_irq, &count);
	struct net_buf *buf = take_pending(0x01);
	net_buf_add_mem(buf, "new", 3);
	complete(buf, 0);
	cdc_acm_irq_rx_enable(&uart);
	drain();
	zassert_equal(count, 3);
}

ZTEST_SUITE(cdc, NULL, NULL, before, NULL, NULL);
