/* SPDX-License-Identifier: Apache-2.0 */
#include "app.h"
#include <zephyr/logging/log.h>
#include <zephyr/net/net_ip.h>
#include <zephyr/sys/atomic.h>

LOG_MODULE_REGISTER(app, LOG_LEVEL_INF);
static modbusHandler_t rtu, tcp;
static atomic_t handlers_ready;
K_MUTEX_DEFINE(rtu_bank_lock);
K_MUTEX_DEFINE(tcp_bank_lock);

void app_transport_reset(bool reset_network)
{
    if (atomic_get(&handlers_ready)) {
        ModbusTransportReset(&rtu);
        if (reset_network) {
            ModbusTransportReset(&tcp);
        }
    }
}

static int start_handlers(void)
{
    int error;
    rtu.uModbusType = IS_ENABLED(CONFIG_APP_MODBUS_CLIENT) ? MB_MASTER : MB_SLAVE;
    rtu.xTypeHW = USB_CDC_HW;
    rtu.port = DEVICE_DT_GET(DT_NODELABEL(modbus_uart));
    rtu.u8id = IS_ENABLED(CONFIG_APP_MODBUS_CLIENT) ? 0 : 10;
    rtu.u16timeOut = 1000;
    rtu.memory_lock = &rtu_bank_lock;
    app_data_init(&rtu.memory, 0);

    tcp.uModbusType = rtu.uModbusType;
    tcp.xTypeHW = TCP_HW;
    tcp.u8id = IS_ENABLED(CONFIG_APP_MODBUS_CLIENT) ? 0 : 1;
    tcp.u16timeOut = 1000;
    tcp.uTcpPort = 502;
    tcp.tcp_idle_ms = 40000;
    tcp.memory_lock = &tcp_bank_lock;
    app_data_init(&tcp.memory, 1);

    error = ModbusInit(&rtu);
    if (error != 0) {
        return error;
    }
    error = ModbusInit(&tcp);
    if (error == 0) {
        error = ModbusStartCDC(&rtu);
    }
    if (error == 0) {
        error = ModbusStart(&tcp);
    }
    if (error != 0) {
        ModbusStop(&rtu);
        ModbusStop(&tcp);
        return error;
    }
    atomic_set(&handlers_ready, 1);
    return 0;
}

static void run_clients(void)
{
    static const uint8_t functions[] = {5, 1, 15, 2, 6, 3, 16, 4};
    struct net_in_addr peer;
    uint32_t cycle = 0;
    if (net_addr_pton(NET_AF_INET, CONFIG_APP_PEER_ADDRESS, &peer) != 0) {
        LOG_ERR("Invalid peer IPv4 address");
        return;
    }
    for (;;) {
        for (size_t i = 0; i < ARRAY_SIZE(functions); ++i) {
            for (unsigned int transport = 0; transport < 2; ++transport) {
                uint16_t data[4] = {1, 0x1234, 0x5678, 0xabcd};
                modbus_t request = {
                    .u8id = transport == 0 ? 10 : 1,
                    .u8fct = functions[i],
                    .u16RegAdd = app_data_address(functions[i]),
                    .u16CoilsNo = (functions[i] == 5 || functions[i] == 6) ? 1 : 4,
                    .u16reg = data,
                    .u16regCapacity = ARRAY_SIZE(data),
                    .u16Port = CONFIG_APP_PEER_PORT,
                    .xIpAddress = peer.s_addr,
                    .u8clientID = 0,
                };
                int result = ModbusQueryV2(transport == 0 ? &rtu : &tcp, request);
                LOG_INF("client cycle=%u transport=%s fc=%u result=%d data0=%u",
                        cycle, transport == 0 ? "rtu" : "tcp", functions[i],
                        result, data[0]);
                k_msleep(CONFIG_APP_QUERY_INTERVAL_MS);
            }
        }
        ++cycle;
    }
}

int main(void)
{
    int error = app_network_init();
    if (error == 0) {
        error = start_handlers();
    }
    if (error == 0) {
        error = app_usb_init();
    }
    if (error != 0) {
        atomic_clear(&handlers_ready);
        ModbusStop(&rtu);
        ModbusStop(&tcp);
        LOG_ERR("Startup failed: %d", error);
        return error;
    }
    LOG_INF("Modbus %s ready: RTU id10, TCP id1 port502",
            IS_ENABLED(CONFIG_APP_MODBUS_CLIENT) ? "client" : "server");
    if (IS_ENABLED(CONFIG_APP_MODBUS_CLIENT)) {
        run_clients();
    }
    return 0;
}
