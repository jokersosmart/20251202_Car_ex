cmake_minimum_required(VERSION 3.15)
project(PowerManagementSafety C Verilog)

# Set C standard
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)

# Set output directories
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)

# Compiler flags
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wall -Wextra -Wpedantic -g -O0 --coverage")
set(CMAKE_C_FLAGS_DEBUG "-g -O0 --coverage")
set(CMAKE_C_FLAGS_RELEASE "-O2")

# Add subdirectories
add_subdirectory(firmware)
add_subdirectory(rtl)
add_subdirectory(verification)

# Enable testing
enable_testing()
