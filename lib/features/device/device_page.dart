import 'package:flutter/material.dart';
import '../../core/adb/adb_service.dart';

class DeviceStatusPage extends StatefulWidget {
  const DeviceStatusPage({super.key});

  @override
  State<DeviceStatusPage> createState() => _DeviceStatusPageState();
}

class _DeviceStatusPageState extends State<DeviceStatusPage> {
  final ADBService adb = ADBService();
  bool loading = true;
  bool connected = false;

  @override
  void initState() {
    super.initState();
    _checkDevice();
  }

  Future<void> _checkDevice() async {
    setState(() => loading = true);
    connected = await adb.isDeviceConnected();
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Estado del dispositivo Android')),
      body: Center(
        child: loading
            ? const CircularProgressIndicator()
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              connected ? Icons.check_circle : Icons.error,
              size: 64,
              color: connected ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              connected
                  ? 'Dispositivo conectado ✅'
                  : 'No hay dispositivo conectado ❌',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _checkDevice,
              child: const Text('Volver a comprobar'),
            ),
          ],
        ),
      ),
    );
  }
}
