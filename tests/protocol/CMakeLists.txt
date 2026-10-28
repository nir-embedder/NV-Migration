cmake_minimum_required(VERSION 3.20)
project(modbus_protocol_tests LANGUAGES C)

include(CTest)
option(MODBUS_SANITIZERS "Enable host AddressSanitizer and UndefinedBehaviorSanitizer" ON)
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_EXTENSIONS OFF)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

add_library(modbus_core STATIC ../../lib/modbus/Src/ModbusCore.c)
target_include_directories(modbus_core PUBLIC ../../lib/modbus/Inc)
add_executable(protocol_tests test_core.c)
target_link_libraries(protocol_tests PRIVATE modbus_core)

if(CMAKE_C_COMPILER_ID MATCHES "Clang|GNU")
    foreach(target modbus_core protocol_tests)
        target_compile_options(${target} PRIVATE
            -Wall -Wextra -Wpedantic -Wconversion -Wshadow -Werror)
        if(MODBUS_SANITIZERS)
            target_compile_options(${target} PRIVATE
                -fsanitize=address,undefined -fno-omit-frame-pointer -fno-sanitize-recover=all)
            target_link_options(${target} PUBLIC -fsanitize=address,undefined)
        endif()
    endforeach()
elseif(MODBUS_SANITIZERS)
    message(FATAL_ERROR "MODBUS_SANITIZERS requires Clang or GCC")
endif()

foreach(suite golden_server golden_client maps server_bounds client_validation
              crc rtu_lengths exhaustive_bits randomized malformed)
    add_test(NAME protocol.${suite} COMMAND protocol_tests ${suite})
    set_tests_properties(protocol.${suite} PROPERTIES
        ENVIRONMENT "ASAN_OPTIONS=halt_on_error=1;UBSAN_OPTIONS=halt_on_error=1:print_stacktrace=1"
        TIMEOUT 60)
endforeach()
