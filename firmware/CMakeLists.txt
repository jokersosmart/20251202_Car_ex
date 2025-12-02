# Firmware CMakeLists.txt

# Create firmware library
add_library(firmware_lib STATIC
    # Placeholder for now - will add sources in Phase 2
)

target_include_directories(firmware_lib PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include)

# Enable testing
add_subdirectory(tests)
