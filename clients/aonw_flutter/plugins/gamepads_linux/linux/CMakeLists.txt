cmake_minimum_required(VERSION 3.20)

set(PROJECT_NAME "gamepads_linux")
project(${PROJECT_NAME} LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(PLUGIN_NAME "${PROJECT_NAME}_plugin")

add_library(${PLUGIN_NAME} SHARED
  "gamepads_linux_plugin.cc"
  "gamepad.h"
  "gamepad.cc"
  "connection_listener.h"
  "connection_listener.cc"
  "utils.h"
  "utils.cc"
)
apply_standard_settings(${PLUGIN_NAME})
set_target_properties(${PLUGIN_NAME} PROPERTIES CXX_VISIBILITY_PRESET hidden)

find_package(PkgConfig REQUIRED)
find_package(Threads REQUIRED)
pkg_check_modules(GTK REQUIRED IMPORTED_TARGET gtk+-3.0)

target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)
target_include_directories(
  ${PLUGIN_NAME}
  INTERFACE "${CMAKE_CURRENT_SOURCE_DIR}/include"
  PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}"
)
target_link_libraries(
  ${PLUGIN_NAME}
  PRIVATE flutter PkgConfig::GTK Threads::Threads
)

set(gamepads_linux_bundled_libraries "" PARENT_SCOPE)
