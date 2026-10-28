/*
 * SPDX-License-Identifier: Apache-2.0
 * USB lifecycle adapted from Zephyr samples/subsys/usb/common/sample_usbd_init.c
 * Copyright (c) 2023 Nordic Semiconductor ASA
 */
#include "app.h"
#include <errno.h>
#include <zephyr/logging/log.h>
#include <zephyr/usb/usbd.h>
#include <zephyr/usb/class/usbd_cdc_acm.h>

LOG_MODULE_REGISTER(app_usb, LOG_LEVEL_INF);
USBD_DEVICE_DEFINE(modbus_usb, DEVICE_DT_GET(DT_NODELABEL(zephyr_udc0)),
                   CONFIG_APP_USB_VID, CONFIG_APP_USB_PID);
USBD_DESC_LANG_DEFINE(language);
USBD_DESC_MANUFACTURER_DEFINE(manufacturer, "NV-Migration");
USBD_DESC_PRODUCT_DEFINE(product, "NK-M3351 Modbus RTU + TCP");
USBD_DESC_SERIAL_NUMBER_DEFINE(serial_number);
USBD_DESC_CONFIG_DEFINE(config_description, "Modbus serial and network");
USBD_CONFIGURATION_DEFINE(fs_configuration, 0, 50, &config_description);

static void cdc_session_reset(const struct device *dev, void *user_data)
{
    ARG_UNUSED(dev);
    ARG_UNUSED(user_data);
    app_transport_reset(false);
}

static void usb_message(struct usbd_context *const context,
                        const struct usbd_msg *const message)
{
    int error = 0;
    if (message->type == USBD_MSG_RESET || message->type == USBD_MSG_VBUS_REMOVED) {
        app_transport_reset(true);
    }
    if (usbd_can_detect_vbus(context)) {
        if (message->type == USBD_MSG_VBUS_READY) {
            error = usbd_enable(context);
        } else if (message->type == USBD_MSG_VBUS_REMOVED) {
            error = usbd_disable(context);
        }
    }
    if (error != 0) {
        LOG_ERR("USB lifecycle error: %d", error);
    }
}

int app_usb_init(void)
{
    int error;
    if (CONFIG_APP_USB_VID == 0 || CONFIG_APP_USB_PID == 0) {
        LOG_ERR("Set assigned APP_USB_VID/PID before enabling USB");
        return -EINVAL;
    }
    struct usbd_desc_node *descriptors[] = {
        &language, &manufacturer, &product, &serial_number,
    };
    for (size_t i = 0; i < ARRAY_SIZE(descriptors); ++i) {
        error = usbd_add_descriptor(&modbus_usb, descriptors[i]);
        if (error != 0) {
            return error;
        }
    }
    error = usbd_add_configuration(&modbus_usb, USBD_SPEED_FS, &fs_configuration);
    if (error != 0) {
        return error;
    }
    error = usbd_register_class(&modbus_usb, "cdc_acm_0", USBD_SPEED_FS, 1);
    if (error != 0) {
        return error;
    }
    error = usbd_register_class(&modbus_usb, "cdc_ecm_0", USBD_SPEED_FS, 1);
    if (error != 0) {
        return error;
    }
    usbd_device_set_code_triple(&modbus_usb, USBD_SPEED_FS,
                               USB_BCC_MISCELLANEOUS, 0x02, 0x01);
    usbd_self_powered(&modbus_usb, false);
    error = usbd_cdc_acm_set_session_cb(DEVICE_DT_GET(DT_NODELABEL(modbus_uart)),
                                       cdc_session_reset, NULL);
    if (error != 0) {
        return error;
    }
    error = usbd_msg_register_cb(&modbus_usb, usb_message);
    if (error == 0) {
        error = usbd_init(&modbus_usb);
    }
    if (error == 0 && !usbd_can_detect_vbus(&modbus_usb)) {
        error = usbd_enable(&modbus_usb);
    }
    return error;
}
