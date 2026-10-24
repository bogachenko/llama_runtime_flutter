#ifndef LLAMA_RUNTIME_FLUTTER_H
#define LLAMA_RUNTIME_FLUTTER_H

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#if defined(_WIN32)
#include <windows.h>
#else
#include <pthread.h>
#include <unistd.h>
#endif

#if defined(_WIN32)
#define FFI_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FFI_PLUGIN_EXPORT
#endif

#ifdef __cplusplus
extern "C" {
#endif

FFI_PLUGIN_EXPORT intptr_t sum(intptr_t a, intptr_t b);
FFI_PLUGIN_EXPORT intptr_t sum_long_running(intptr_t a, intptr_t b);
FFI_PLUGIN_EXPORT int llama_runtime_device_count(void);
FFI_PLUGIN_EXPORT int llama_runtime_rpc_server_start(int port, int threads);
FFI_PLUGIN_EXPORT int llama_runtime_rpc_server_stop(void);
FFI_PLUGIN_EXPORT int llama_runtime_rpc_server_is_running(void);

#ifdef __cplusplus
}
#endif

#endif
