import 'package:flutter/material.dart';
import 'package:llama_runtime_flutter/llama_runtime_flutter.dart'
    as llama_runtime;

void main() => runApp(const RpcExampleApp());

class RpcExampleApp extends StatelessWidget {
  const RpcExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'llama_runtime_flutter example',
      theme: ThemeData(useMaterial3: true),
      home: const RpcExamplePage(),
    );
  }
}

class RpcExamplePage extends StatefulWidget {
  const RpcExamplePage({super.key});

  @override
  State<RpcExamplePage> createState() => _RpcExamplePageState();
}

class _RpcExamplePageState extends State<RpcExamplePage> {
  static const int _port = 50052;
  static const int _threads = 4;

  int? _deviceCount;
  bool _running = false;
  bool _busy = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final devices = await llama_runtime.llamaRuntimeDeviceCount();
      final running = await llama_runtime.isRpcServerRunning();
      if (!mounted) return;
      setState(() {
        _deviceCount = devices;
        _running = running;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _start() => _perform(() async {
    await llama_runtime.startRpcServer(port: _port, threads: _threads);
  });

  Future<void> _stop() => _perform(llama_runtime.stopRpcServer);

  Future<void> _perform(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await action();
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      try {
        final running = await llama_runtime.isRpcServerRunning();
        if (mounted) setState(() => _running = running);
      } catch (error) {
        if (mounted) setState(() => _error ??= error.toString());
      }
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('llama_runtime_flutter')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('GGML devices: ${_deviceCount ?? '—'}'),
              const SizedBox(height: 20),
              const Text('RPC server', style: TextStyle(fontSize: 22)),
              const SizedBox(height: 12),
              Text('Status: ${_running ? 'Running' : 'Stopped'}'),
              const Text('Port: $_port'),
              const Text('Threads: $_threads'),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                children: [
                  FilledButton(
                    onPressed: _busy || _running ? null : _start,
                    child: const Text('Start RPC'),
                  ),
                  OutlinedButton(
                    onPressed: _busy || !_running ? null : _stop,
                    child: const Text('Stop RPC'),
                  ),
                  IconButton(
                    tooltip: 'Refresh status',
                    onPressed: _busy ? null : _refresh,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              if (_busy) ...[
                const SizedBox(height: 12),
                const LinearProgressIndicator(),
              ],
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  'Last error: $_error',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 24),
              const Text('RPC has no authentication. Use trusted LANs only.'),
            ],
          ),
        ),
      ),
    );
  }
}
