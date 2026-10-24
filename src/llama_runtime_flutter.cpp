#include "llama_runtime_flutter.h"
#include "ggml-backend.h"
#include "ggml-rpc.h"
#include <mutex>
#include <string>

namespace {
std::once_flag g_backend_load_once;
std::mutex g_rpc_server_mutex;
ggml_rpc_server_handle * g_rpc_server = nullptr;

void ensure_backends_loaded() {
    std::call_once(g_backend_load_once, []() {
        ggml_backend_load_all();
    });
}
}

extern "C" FFI_PLUGIN_EXPORT int llama_runtime_device_count(void) {
    ensure_backends_loaded();
    return static_cast<int>(ggml_backend_dev_count());
}

extern "C" FFI_PLUGIN_EXPORT int llama_runtime_rpc_server_start(int port, int threads) {
    if (port < 1 || port > 65535 || threads < 1 || threads > 256) {
        return -1;
    }

    std::lock_guard<std::mutex> lock(g_rpc_server_mutex);
    if (g_rpc_server) {
        if (ggml_backend_rpc_server_is_running(g_rpc_server)) {
            return -2;
        }
        ggml_backend_rpc_server_stop(g_rpc_server);
        g_rpc_server = nullptr;
    }

    ensure_backends_loaded();
    ggml_backend_dev_t cpu = ggml_backend_dev_by_type(GGML_BACKEND_DEVICE_TYPE_CPU);
    if (!cpu) {
        return -1;
    }

    ggml_backend_dev_t devices[] = {cpu};
    const std::string endpoint = "0.0.0.0:" + std::to_string(port);
    g_rpc_server = ggml_backend_rpc_server_start(
        endpoint.c_str(), nullptr, static_cast<size_t>(threads), 1, devices);
    return g_rpc_server ? 0 : -1;
}

extern "C" FFI_PLUGIN_EXPORT int llama_runtime_rpc_server_stop(void) {
    std::lock_guard<std::mutex> lock(g_rpc_server_mutex);
    if (g_rpc_server) {
        ggml_backend_rpc_server_stop(g_rpc_server);
        g_rpc_server = nullptr;
    }
    return 0;
}

extern "C" FFI_PLUGIN_EXPORT int llama_runtime_rpc_server_is_running(void) {
    std::lock_guard<std::mutex> lock(g_rpc_server_mutex);
    return g_rpc_server && ggml_backend_rpc_server_is_running(g_rpc_server) ? 1 : 0;
}
// A very short-lived native function.
//
// For very short-lived functions, it is fine to call them on the main isolate.
// They will block the Dart execution while running the native function, so
// only do this for native functions which are guaranteed to be short-lived.
FFI_PLUGIN_EXPORT intptr_t sum(intptr_t a, intptr_t b) {
#ifdef DEBUG
  return a + b + 1000;
#else
  return a + b;
#endif
}

// A longer-lived native function, which occupies the thread calling it.
//
// Do not call these kind of native functions in the main isolate. They will
// block Dart execution. This will cause dropped frames in Flutter applications.
// Instead, call these native functions on a separate isolate.
FFI_PLUGIN_EXPORT intptr_t sum_long_running(intptr_t a, intptr_t b) {
  // Simulate work.
#if _WIN32
  Sleep(5000);
#else
  usleep(5000 * 1000);
#endif
  return a + b;
}
