cmake_minimum_required(VERSION 3.22)

project(llama_runtime_flutter LANGUAGES C CXX ASM)

set(CMAKE_POSITION_INDEPENDENT_CODE ON)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Первая версия: CPU + RPC, без дополнительных GPU-бэкендов.
set(BUILD_SHARED_LIBS OFF CACHE BOOL "" FORCE)
set(GGML_RPC ON CACHE BOOL "" FORCE)
set(GGML_OPENMP OFF CACHE BOOL "" FORCE)
set(GGML_NATIVE OFF CACHE BOOL "" FORCE)
set(GGML_CCACHE OFF CACHE BOOL "" FORCE)

add_subdirectory(
    third_party/llama.cpp/ggml
    ${CMAKE_CURRENT_BINARY_DIR}/ggml
)

add_library(llama_runtime_flutter SHARED
    src/llama_runtime_flutter.cpp
)

target_link_libraries(llama_runtime_flutter PRIVATE
    ggml
    ggml-rpc
)

install(
    TARGETS llama_runtime_flutter
    LIBRARY DESTINATION lib
)