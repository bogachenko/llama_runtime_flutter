cmake_minimum_required(VERSION 3.22)

project(llama_runtime_flutter LANGUAGES CXX)

add_library(llama_runtime_flutter SHARED
    src/llama_runtime_flutter.cpp
)

target_compile_features(llama_runtime_flutter PRIVATE cxx_std_17)

install(
    TARGETS llama_runtime_flutter
    LIBRARY DESTINATION lib
)