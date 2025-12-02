# Firmware Tests CMakeLists.txt

# Find Python and pytest
find_package(Python3 COMPONENTS Interpreter REQUIRED)

# Unit tests target
add_custom_target(unit_tests
    COMMAND ${Python3_EXECUTABLE} -m pytest unit/ -v --cov=../src
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    COMMENT "Running firmware unit tests"
)

# Integration tests target
add_custom_target(integration_tests
    COMMAND ${Python3_EXECUTABLE} -m pytest integration/ -v --cov=../src
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    COMMENT "Running firmware integration tests"
)

# All tests target
add_custom_target(all_tests
    COMMAND ${Python3_EXECUTABLE} -m pytest -v --cov=../src
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    COMMENT "Running all firmware tests"
)

# Add as test dependencies
add_test(
    NAME firmware_all_tests
    COMMAND ${Python3_EXECUTABLE} -m pytest -v --cov=../src
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
)
