/* SPDX-License-Identifier: Apache-2.0 */
#include "app.h"
#include <errno.h>
#include <zephyr/logging/log.h>
#include <zephyr/net/net_if.h>
#include <zephyr/net/net_ip.h>

LOG_MODULE_REGISTER(app_network, LOG_LEVEL_INF);

int app_network_init(void)
{
    const struct device *device = DEVICE_DT_GET(DT_NODELABEL(cdc_ecm_eth0));
    struct net_in_addr address, netmask;
    struct net_if *iface;
    int error;

    if (!device_is_ready(device)) {
        return -ENODEV;
    }
    iface = net_if_lookup_by_dev(device);
    if (iface == NULL ||
        net_addr_pton(NET_AF_INET, CONFIG_APP_IP_ADDRESS, &address) != 0 ||
        net_addr_pton(NET_AF_INET, "255.255.255.0", &netmask) != 0) {
        return -EINVAL;
    }
    if (net_if_ipv4_addr_add(iface, &address, NET_ADDR_MANUAL, 0) == NULL ||
        !net_if_ipv4_set_netmask_by_addr(iface, &address, &netmask)) {
        return -ENOMEM;
    }
    error = net_if_up(iface);
    if (error != 0 && error != -EALREADY) {
        return error;
    }
    LOG_INF("USB network %s/24; no gateway", CONFIG_APP_IP_ADDRESS);
    return 0;
}
