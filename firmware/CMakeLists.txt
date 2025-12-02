# Firmware CMakeLists.txt

# Create firmware library
add_library(firmware_lib STATIC
    # Phase 2: Foundational Infrastructure
    src/hal/interrupt_handler.c
    src/hal/power_api.c
    src/safety/safety_fsm.c
    src/safety/fault_aggregator.c
    src/safety/fault_statistics.c
    
    # Phase 3: Power Safety Implementation
    src/power/pwr_event_handler.c
    src/power/pwr_monitor_service.c
)

target_include_directories(firmware_lib PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include)

# Set C standard to C11 with safety extensions
set_target_properties(firmware_lib PROPERTIES
    C_STANDARD 11
    C_STANDARD_REQUIRED ON
    C_EXTENSIONS ON
)

# Compiler flags for safety (ARM Cortex-M4 specific)
target_compile_options(firmware_lib PRIVATE
    -mcpu=cortex-m4
    -mfpu=fpv4-sp-d16
    -mfloat-abi=hard
    -Wall -Wextra -Werror
    -fstack-usage
    -fno-common
    -ffunction-sections
    -fdata-sections
)

# Enable coverage analysis
if(ENABLE_COVERAGE)
    target_compile_options(firmware_lib PRIVATE --coverage)
    target_link_options(firmware_lib PRIVATE --coverage)
endif()

# Enable testing
add_subdirectory(tests)
