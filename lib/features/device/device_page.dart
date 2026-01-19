import 'package:flutter/material.dart';
import '../../core/adb/adb_service.dart';
import '../../widgets/action_button.dart';

class DevicePage extends StatefulWidget {
  const DevicePage({super.key});

  @override
  State<DevicePage> createState() => _DevicePageState();
}

class _DevicePageState extends State<DevicePage> {
  bool _isConnected = false;
  bool _loading = false;
  late final ADBService _adbService;

  @override
  void initState() {
    super.initState();

    _adbService = ADBService();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkConnection();
    });
  }

  Future<void> checkConnection() async {
    if (_loading) return;

    setState(() => _loading = true);
    try {
      final connected = await _adbService.isDeviceConnected();
      setState(() {
        _isConnected = connected;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _isConnected = false;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dispositivo Android')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _loading
                ? const CircularProgressIndicator()
                : Icon(
              _isConnected ? Icons.check_circle : Icons.cancel,
              color: _isConnected ? Colors.green : Colors.red,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              _isConnected ? 'Dispositivo conectado' : 'No hay dispositivo conectado',
              style: Theme.of(context).textTheme.titleMedium, // Aquí SÍ puedes usar Theme.of
            ),
            const SizedBox(height: 32),
            ActionButton(
              text: 'Comprobar conexión',
              onPressed: checkConnection,
              isLoading: _loading,
            ),
          ],
        ),
      ),
    );
  }
}