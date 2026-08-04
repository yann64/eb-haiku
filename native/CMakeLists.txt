# Standalone build for eb-haiku's native shim - NOT driven by ebpm
# (neither ebc nor ebpm compiles a package's own native code today; this
# is built and installed once, independently, the same way libbe.so
# itself is already present on any real Haiku system). Produces
# libebhaikushim.a, linked against Haiku's own libbe via the package's
# `Extern "C" Lib "ebhaikushim"` declarations in src/raw/haiku_shim.bas.
#
# Build (on real Haiku hardware - this shim links against libbe.so,
# which only exists there):
#   cmake -S native -B native/build
#   cmake --build native/build
#   sudo cp native/build/libebhaikushim.a /boot/system/develop/lib/
# (or install wherever your own -L search path already looks; see this
# package's own README).

cmake_minimum_required(VERSION 3.16)
project(ebhaikushim CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_library(ebhaikushim STATIC shim.cpp shim_interface.cpp shim_translation.cpp)
target_include_directories(ebhaikushim PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
