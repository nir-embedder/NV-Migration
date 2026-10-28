# SPDX-License-Identifier: LGPL-2.1-only
# Modified 2026-10-28 for NV-Migration: application-side library integration.
# No Zephyr Modbus dependency.
if(CONFIG_MODBUS_PORT)
  add_library(modbus_port STATIC Src/Modbus.c Src/ModbusCore.c)
  target_link_libraries(modbus_port PUBLIC zephyr_interface)
  target_include_directories(modbus_port PUBLIC Inc Config)
  add_dependencies(modbus_port zephyr_generated_headers)
  if(CONFIG_MODBUS_PORT_RTU)
    target_sources(modbus_port PRIVATE Src/ModbusRtu.c)
  endif()
  if(CONFIG_MODBUS_PORT_TCP)
    target_sources(modbus_port PRIVATE Src/ModbusTcp.c)
  endif()
  target_link_libraries(app PUBLIC modbus_port)
endif()
