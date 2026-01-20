import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;

import '../../core/adb/adb_service.dart';
import '../../core/filesystem/file_item.dart';

import 'package:http/http.dart' as http;
import 'package:archive/archive_io.dart';

class OrganizerPage extends StatefulWidget {
  const OrganizerPage({super.key});

  @override
  State<OrganizerPage> createState() => _OrganizerPageState();
}

class _OrganizerPageState extends State<OrganizerPage> {
  late final ADBService adbService;

  bool? isDeviceConnected;
  bool _loading = false;

  List<FileItem> _tree = [];

  @override
  void initState() {
    super.initState();
    adbService = ADBService();
  }

  /* =========================
     BOTÓN PRINCIPAL — VERIFICAR CONEXIÓN
     ========================= */
  Future<void> _checkConnection() async {
    setState(() => _loading = true);

    final connected = await adbService.isDeviceConnected();
    isDeviceConnected = connected;

    if (!connected) {
      _tree.clear();
      _showMessage('No hay dispositivo conectado', error: true);
      setState(() => _loading = false);
      return;
    }

    _showMessage('Dispositivo conectado correctamente');
    await _buildRootTree();

    setState(() => _loading = false);
  }

  /* =========================
     CONSTRUIR RAÍCES
     ========================= */
  Future<void> _buildRootTree() async {
    final roots = <FileItem>[];

    // Almacenamiento interno
    const internal = '/storage/emulated/0';
    roots.add(
      FileItem(
        name: 'Almacenamiento interno',
        path: internal,
        children: await _loadDirectories(internal),
      ),
    );

    // SD externa real (UUID tipo ED7B-CBA2)
    try {
      final storageDirs = await adbService.listDirectories('/storage');
      for (final dir in storageDirs) {
        if (RegExp(r'^[A-Z0-9]{4}-[A-Z0-9]{4}$').hasMatch(dir)) {
          final fullPath = '/storage/$dir';
          roots.add(
            FileItem(
              name: 'Tarjeta SD ($dir)',
              path: fullPath,
              children: await _loadDirectories(fullPath),
            ),
          );
        }
      }
    } catch (_) {
      // Ignorar errores de listado
    }

    setState(() => _tree = roots);
  }

  /* =========================
     CARGAR SOLO CARPETAS
     ========================= */
  Future<List<FileItem>> _loadDirectories(String path) async {
    final dirs = await adbService.listDirectories(path);
    return dirs
        .map(
          (d) => FileItem(
        name: d,
        path: '$path/$d',
        children: [],
      ),
    )
        .toList();
  }

  /* =========================
     UI TREE
     ========================= */
  Widget _buildItem(FileItem item) {
    return ExpansionTile(
      leading: const Icon(Icons.folder, color: Colors.blue),
      title: Text(item.name),
      children: item.children.map(_buildItem).toList(),
      onExpansionChanged: (open) async {
        if (open && item.children.isEmpty) {
          final children = await _loadDirectories(item.path);
          setState(() => item.children.addAll(children));
        }
      },
    );
  }

/* =========================
     INICIAR SCRCPY -
     ========================= */
  Future<void> _startScrcpy() async {
    if (isDeviceConnected != true) {
      _showMessage('No hay dispositivo conectado', error: true);
      return;
    }

    try {
      if (Platform.isWindows) {
        await Process.start(
            'assets/adb/windows/scrcpy.exe',
            [],
            mode: ProcessStartMode.detachedWithStdio
        );
        _showMessage('scrcpy iniciado');

      } else if (Platform.isLinux) {
        // SIEMPRE usar tu instalación local
        final homeDir = Platform.environment['HOME']!;
        final scrcpyPath = '$homeDir/scrcpy-linux-x86_64-v3.3.4/scrcpy';

        // Verificar que existe
        final file = File(scrcpyPath);
        if (!await file.exists()) {
          _showMessage('Error: scrcpy no encontrado en $scrcpyPath', error: true);
          return;
        }

        // Verificar conexión ADB primero
        _showMessage('Verificando conexión ADB...');
        final adbResult = await Process.run('adb', ['devices']);
        print('ADB Devices: ${adbResult.stdout}');

        // Ejecutar scrcpy con argumentos básicos
        _showMessage('Iniciando scrcpy...');

        await Process.run('bash', [
          '-c',
          '''
          cd "$homeDir/scrcpy-linux-x86_64-v3.3.4" && 
          ./scrcpy --always-on-top --max-size=1920
          '''
        ], runInShell: true);

        _showMessage('scrcpy ejecutado');
      }

    } catch (e) {
      _showMessage('Error: $e', error: true);
      print('Error detallado: $e');
    }
  }

  /* =========================
     MENSAJES DE FEEDBACK
     ========================= */
  void _showMessage(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.red : Colors.green,
      ),
    );
  }

  /* =========================
     UI PRINCIPAL
     ========================= */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Photo Organizer')),
      body: Row(
        children: [
          // IZQUIERDA — árbol (30%)
          Flexible(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                border: Border(right: BorderSide(color: Colors.grey.shade300)),
              ),
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _tree.isEmpty
                  ? Center(
                child: Text(
                  isDeviceConnected == true
                      ? 'Sin carpetas'
                      : 'Dispositivo no conectado',
                ),
              )
                  : ListView(
                padding: const EdgeInsets.all(8),
                children: _tree.map(_buildItem).toList(),
              ),
            ),
          ),

          // DERECHA — acciones (70%)
          Flexible(
            flex: 7,
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ElevatedButton.icon(
                    onPressed: _loading ? null : _checkConnection,
                    icon: const Icon(Icons.usb),
                    label: const Text('Verificar conexión'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed:
                    (isDeviceConnected == true) ? _startScrcpy : null,
                    icon: const Icon(Icons.screen_share),
                    label: const Text('Iniciar scrcpy'),
                  ),
                  const SizedBox(height: 24),
                  if (isDeviceConnected != null)
                    Text(
                      isDeviceConnected!
                          ? 'Estado: CONECTADO'
                          : 'Estado: DESCONECTADO',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDeviceConnected! ? Colors.green : Colors.red,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
