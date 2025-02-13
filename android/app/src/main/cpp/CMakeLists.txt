cmake_minimum_required(VERSION 3.10)

project(decoder)

set(CMAKE_CXX_STANDARD 17)

add_library(decoder SHARED decoder.cpp)

find_library(log-lib log)

target_link_libraries(decoder ${log-lib})
