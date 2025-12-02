# RTL CMakeLists.txt

# Verilator simulation configuration
find_program(VERILATOR verilator)

if(VERILATOR)
    message(STATUS "Verilator found: ${VERILATOR}")
    set(VERILATOR_FLAGS -f ${CMAKE_CURRENT_SOURCE_DIR}/verilator.cfg)
else()
    message(WARNING "Verilator not found - RTL simulation disabled")
endif()

# Add RTL targets placeholder
add_custom_target(rtl_sim
    COMMAND ${VERILATOR} ${VERILATOR_FLAGS}
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    COMMENT "Building RTL simulation with Verilator"
)
