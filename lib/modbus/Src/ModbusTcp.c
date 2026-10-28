/* SPDX-License-Identifier: LGPL-2.1-only
 * Zephyr socket adaptation of upstream Modbus.c TCPwaitConnData,
 * TCPinitserver and TCP master connection slots at commit
 * 9c022fd2538edb5b53e2e07c98ebbe9a4685546c.
 * Original author: Alejandro Mera (May 5, 2020), adapted from
 * https://github.com/smarmengol/Modbus-Master-Slave-for-Arduino.
 * Modified 2026-10-28 for NV-Migration: nonblocking Zephyr stream parsing,
 * exact MBAP validation, elapsed idle expiry and partial I/O.
 */
#include "Modbus.h"
#include <zephyr/net/socket.h>
#include <zephyr/sys/byteorder.h>
#include <errno.h>
#include <string.h>

int mb_tcp_adu_length(const uint8_t *data, size_t length)
{
	if (data == NULL) {
		return -EINVAL;
	}
	if (length >= 4U && (data[2] != 0U || data[3] != 0U)) {
		return -EBADMSG;
	}
	if (length < 6U) {
		return 0;
	}
	uint16_t body = sys_get_be16(data + 4);

	if (body < 2U || body > 254U) {
		return -EBADMSG;
	}
	if ((size_t)body + 6U > MB_TCP_BUFFER_SIZE) {
		return -EMSGSIZE;
	}
	return (int)body + 6;
}

static int nonblocking(int fd)
{
	if (zsock_fcntl(fd, ZVFS_F_SETFL, ZVFS_O_NONBLOCK) < 0) {
		return -errno;
	}
	return 0;
}

static void close_peer(modbusHandler_t *h, size_t i, int result)
{
	struct mb_private *p = &h->_private;
	struct mb_tcp_peer *peer = &p->peers[i];

	if (peer->fd >= 0) {
		zsock_close(peer->fd);
	}
	memset(peer, 0, sizeof(*peer));
	peer->fd = -1;
	if (result != 0 && p->active_valid && p->active.u8clientID == i) {
		mb_complete(h, result);
	}
}

void mb_tcp_reset(modbusHandler_t *h)
{
	for (size_t i = 0; i < MB_TCP_CONNECTIONS; i++) {
		close_peer(h, i, 0);
	}
}

void mb_tcp_stop(modbusHandler_t *h)
{
	mb_tcp_reset(h);
	if (h->_private.listener >= 0) {
		zsock_close(h->_private.listener);
		h->_private.listener = -1;
	}
}

int mb_tcp_start(modbusHandler_t *h)
{
	struct net_sockaddr_in address = {
		.sin_family = NET_AF_INET,
		.sin_port = sys_cpu_to_be16(h->uTcpPort),
		.sin_addr.s_addr = sys_cpu_to_be32(NET_INADDR_ANY),
	};
	int ret;
	int fd;

	mb_tcp_reset(h);
	if (h->uModbusType == MB_MASTER) {
		return 0;
	}
	fd = zsock_socket(NET_AF_INET, NET_SOCK_STREAM, NET_IPPROTO_TCP);
	if (fd < 0) {
		return -errno;
	}
	ret = nonblocking(fd);
	if (ret == 0 && zsock_bind(fd, (struct net_sockaddr *)&address, sizeof(address)) < 0) {
		ret = -errno;
	}
	if (ret == 0 && zsock_listen(fd, MB_TCP_CONNECTIONS) < 0) {
		ret = -errno;
	}
	if (ret != 0) {
		zsock_close(fd);
		return ret;
	}
	h->_private.listener = fd;
	return 0;
}

static void accept_peers(modbusHandler_t *h)
{
	struct mb_private *p = &h->_private;

	/* One extra accept lets a full pool explicitly reject new connections. */
	for (size_t attempts = 0; attempts <= MB_TCP_CONNECTIONS; attempts++) {
		int fd = zsock_accept(p->listener, NULL, NULL);
		size_t slot;

		if (fd < 0) {
			break;
		}
		for (slot = 0; slot < MB_TCP_CONNECTIONS; slot++) {
			if (p->peers[slot].fd < 0) {
				break;
			}
		}
		if (slot == MB_TCP_CONNECTIONS || nonblocking(fd) != 0) {
			zsock_close(fd);
			continue;
		}
		p->peers[slot].fd = fd;
		p->peers[slot].last_activity = k_uptime_get();
	}
}

static void begin_query(modbusHandler_t *h)
{
	struct mb_private *p = &h->_private;
	modbus_t *q = &p->active;
	struct mb_tcp_peer *peer = &p->peers[q->u8clientID];
	uint16_t port = q->u16Port == 0U ? 502U : q->u16Port;
	int n;

	/* A slot is an endpoint cache, never permission to send to an old host. */
	if (peer->fd >= 0 && (peer->address != q->xIpAddress || peer->port != port)) {
		close_peer(h, q->u8clientID, 0);
	}
	n = mb_core_build(q, peer->tx + 7, sizeof(peer->tx) - 7U);
	if (n < 0) {
		mb_complete(h, n);
		return;
	}
	if (peer->fd < 0) {
		struct net_sockaddr_in address = {
			.sin_family = NET_AF_INET,
			.sin_port = sys_cpu_to_be16(port),
			.sin_addr.s_addr = q->xIpAddress,
		};
		int ret;

		peer->fd = zsock_socket(NET_AF_INET, NET_SOCK_STREAM, NET_IPPROTO_TCP);
		if (peer->fd < 0) {
			mb_complete(h, -errno);
			return;
		}
		peer->address = q->xIpAddress;
		peer->port = port;
		ret = nonblocking(peer->fd);
		if (ret == 0 && zsock_connect(peer->fd, (struct net_sockaddr *)&address, sizeof(address)) < 0) {
			if (errno == EINPROGRESS || errno == EALREADY || errno == EWOULDBLOCK) {
				peer->connecting = true;
			} else {
				ret = -errno;
			}
		}
		if (ret != 0) {
			close_peer(h, q->u8clientID, ret);
			return;
		}
	}
	p->transaction++;
	sys_put_be16(p->transaction, peer->tx);
	sys_put_be16(0, peer->tx + 2);
	sys_put_be16((uint16_t)n + 1U, peer->tx + 4);
	peer->tx[6] = q->u8id;
	peer->tx_len = (size_t)n + 7U;
	peer->tx_offset = 0;
	peer->rx_len = 0;
	peer->last_activity = k_uptime_get();
}

static void consume_frame(modbusHandler_t *h, size_t i, size_t length)
{
	struct mb_private *p = &h->_private;
	struct mb_tcp_peer *peer = &p->peers[i];
	int n;

	if (h->uModbusType == MB_MASTER) {
		if (!p->active_valid || p->active.u8clientID != i ||
		    peer->rx[6] != p->active.u8id ||
		    sys_get_be16(peer->rx) != p->transaction) {
			close_peer(h, i, -EBADMSG);
			return;
		}
		n = mb_core_parse(&p->active, peer->rx + 7, length - 7U);
		mb_complete(h, n);
		if (n < 0) {
			close_peer(h, i, 0);
			return;
		}
	} else if (peer->rx[6] == h->u8id) {
		n = mb_server(h, peer->rx + 7, length - 7U, peer->tx + 7, sizeof(peer->tx) - 7U);
		if (n > 0) {
			memcpy(peer->tx, peer->rx, 7);
			sys_put_be16((uint16_t)n + 1U, peer->tx + 4);
			peer->tx_len = (size_t)n + 7U;
			peer->tx_offset = 0;
		}
	}
	peer->rx_len -= length;
	memmove(peer->rx, peer->rx + length, peer->rx_len);
}

static void parse_frames(modbusHandler_t *h, size_t i)
{
	struct mb_tcp_peer *peer = &h->_private.peers[i];

	while (peer->fd >= 0 && peer->tx_len == 0U && peer->rx_len != 0U) {
		int length = mb_tcp_adu_length(peer->rx, peer->rx_len);

		if (length < 0) {
			close_peer(h, i, length);
			return;
		}
		if (length == 0 || peer->rx_len < (size_t)length) {
			return;
		}
		consume_frame(h, i, (size_t)length);
	}
}

static void service_peer(modbusHandler_t *h, size_t i, short events)
{
	struct mb_tcp_peer *peer = &h->_private.peers[i];

	if (peer->connecting && (events & (ZSOCK_POLLOUT | ZSOCK_POLLERR | ZSOCK_POLLHUP))) {
		int error = 0;
		net_socklen_t len = sizeof(error);

		if (zsock_getsockopt(peer->fd, ZSOCK_SOL_SOCKET, ZSOCK_SO_ERROR, &error, &len) < 0) {
			close_peer(h, i, -errno);
			return;
		}
		if (error != 0) {
			close_peer(h, i, -error);
			return;
		}
		peer->connecting = false;
	}
	if (!peer->connecting && (events & ZSOCK_POLLOUT) && peer->tx_len != 0U) {
		ssize_t n = zsock_send(peer->fd, peer->tx + peer->tx_offset,
				       peer->tx_len - peer->tx_offset, 0);

		if (n > 0) {
			peer->tx_offset += (size_t)n;
			peer->last_activity = k_uptime_get();
			if (peer->tx_offset == peer->tx_len) {
				peer->tx_len = 0;
				peer->tx_offset = 0;
			}
		} else if (n == 0 || (errno != EAGAIN && errno != EWOULDBLOCK && errno != EINTR)) {
			close_peer(h, i, n == 0 ? -ECONNRESET : -errno);
			return;
		}
	}
	parse_frames(h, i);
	if (peer->fd < 0) {
		return;
	}
	if (!peer->connecting && peer->tx_len == 0U && (events & ZSOCK_POLLIN)) {
		ssize_t n = zsock_recv(peer->fd, peer->rx + peer->rx_len,
				       sizeof(peer->rx) - peer->rx_len, 0);

		if (n > 0) {
			peer->rx_len += (size_t)n;
			peer->last_activity = k_uptime_get();
			parse_frames(h, i);
		} else if (n == 0 || (errno != EAGAIN && errno != EWOULDBLOCK && errno != EINTR)) {
			close_peer(h, i, n == 0 ? -ECONNRESET : -errno);
			return;
		}
	}
	if (peer->fd >= 0 && (events & (ZSOCK_POLLERR | ZSOCK_POLLHUP | ZSOCK_POLLNVAL))) {
		close_peer(h, i, -ECONNRESET);
	}
}

void mb_tcp_step(modbusHandler_t *h)
{
	struct mb_private *p = &h->_private;
	struct zsock_pollfd fds[MB_TCP_CONNECTIONS + 1];
	int64_t now = k_uptime_get();

	if (p->active_valid && now >= p->deadline) {
		close_peer(h, p->active.u8clientID, -ETIMEDOUT);
	}
	for (size_t i = 0; i < MB_TCP_CONNECTIONS; i++) {
		if (p->peers[i].fd >= 0 && now - p->peers[i].last_activity >= h->tcp_idle_ms) {
			close_peer(h, i, -ETIMEDOUT);
		}
		parse_frames(h, i);
	}
	if (h->uModbusType == MB_MASTER && mb_take_query(h)) {
		begin_query(h);
	}
	fds[0] = (struct zsock_pollfd){ .fd = p->listener, .events = ZSOCK_POLLIN };
	for (size_t i = 0; i < MB_TCP_CONNECTIONS; i++) {
		struct mb_tcp_peer *peer = &p->peers[i];

		fds[i + 1] = (struct zsock_pollfd){
			.fd = peer->fd,
			.events = peer->connecting || peer->tx_len != 0U ? ZSOCK_POLLOUT : ZSOCK_POLLIN,
		};
	}
	/* Individual nonblocking polls avoid imposing a larger global
	 * CONFIG_ZVFS_POLL_MAX on applications. All slots run every iteration.
	 */
	for (size_t i = 0; i < ARRAY_SIZE(fds); i++) {
		if (fds[i].fd < 0) {
			continue;
		}
		if (zsock_poll(&fds[i], 1, 0) < 0) {
			if (errno != EINTR) {
				int result = -errno;

				mb_tcp_reset(h);
				mb_complete(h, result);
			}
			return;
		}
	}
	if (fds[0].revents & ZSOCK_POLLIN) {
		accept_peers(h);
	}
	for (size_t i = 0; i < MB_TCP_CONNECTIONS; i++) {
		/* A newly accepted descriptor has no poll result yet. */
		if (p->peers[i].fd >= 0 && p->peers[i].fd == fds[i + 1].fd) {
			service_peer(h, i, fds[i + 1].revents);
		}
	}
}
