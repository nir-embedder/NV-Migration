cmake_minimum_required(VERSION 3.20.0)
find_package(Zephyr REQUIRED HINTS $ENV{ZEPHYR_BASE})
project(cdc_session_regression)
target_sources(app PRIVATE src/main.c)
target_include_directories(app PRIVATE ${ZEPHYR_BASE}/subsys/usb/device_next)
# Compile the real pinned driver; only its USB/UDC boundary is mocked.
target_compile_definitions(app PRIVATE
  CONFIG_USBD_MAX_SPEED=0
  CONFIG_USBD_CDC_ACM_LOG_LEVEL=0
  CONFIG_USBD_CDC_ACM_TX_DELAY_MS=100
  CONFIG_USBD_CDC_ACM_STACK_SIZE=2048
  CONFIG_USBD_CDC_ACM_WORKQUEUE=$<BOOL:${CDC_DEDICATED_WORKQUEUE}>)
