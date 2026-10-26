cmake_minimum_required(VERSION 3.10)
project(chiaki_session_lifecycle_tests LANGUAGES CXX)
enable_testing()
find_package(Threads REQUIRED)
add_executable(session-resource-unit resource.cpp)
target_include_directories(session-resource-unit PRIVATE ../../gui/include)
target_compile_features(session-resource-unit PRIVATE cxx_std_11)
target_link_libraries(session-resource-unit PRIVATE Threads::Threads)
add_test(NAME session-resource COMMAND session-resource-unit)
add_executable(stream-health-unit health.cpp)
target_include_directories(stream-health-unit PRIVATE ../../gui/include)
target_compile_features(stream-health-unit PRIVATE cxx_std_11)
add_test(NAME stream-health COMMAND stream-health-unit)
find_package(Python3 COMPONENTS Interpreter REQUIRED)
set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS
    ${CMAKE_CURRENT_SOURCE_DIR}/generate-login-test.py
    ${CMAKE_CURRENT_SOURCE_DIR}/../../lib/src/ctrl.c
    ${CMAKE_CURRENT_SOURCE_DIR}/../../lib/src/session.c)
execute_process(COMMAND ${Python3_EXECUTABLE}
    ${CMAKE_CURRENT_SOURCE_DIR}/generate-login-test.py ${CMAKE_CURRENT_BINARY_DIR}/login.cpp
    RESULT_VARIABLE login_test_generated)
if(NOT login_test_generated EQUAL 0)
    message(FATAL_ERROR "Could not generate login regression test")
endif()
add_executable(login-state-unit ${CMAKE_CURRENT_BINARY_DIR}/login.cpp)
target_compile_features(login-state-unit PRIVATE cxx_std_11)
add_test(NAME login-state COMMAND login-state-unit)
if(NOT MSVC)
    find_package(Python3 COMPONENTS Interpreter REQUIRED)
    add_test(NAME network-recovery COMMAND ${Python3_EXECUTABLE}
        ${CMAKE_CURRENT_SOURCE_DIR}/network.py ${CMAKE_CXX_COMPILER})
    add_test(NAME direct-controller COMMAND ${Python3_EXECUTABLE}
        ${CMAKE_CURRENT_SOURCE_DIR}/direct-controller.py ${CMAKE_CXX_COMPILER})
endif()
