import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

import '../../core/adb/adb_service.dart';
import '../../core/adb/media_extractor.dart';
import 'package:photo_organizer_pc/features/organizer/models/file_item.dart';

class OrganizerPage extends StatefulWidget {
  const OrganizerPage({super.key});

  @override
  State<OrganizerPage> createState() => _OrganizerPageState();
}

class _OrganizerPageState extends State<OrganizerPage> {
  late final ADBService adbService;
  late final MediaExtractorService extractorService;

  bool? isDeviceConnected;
  bool _loading = false;
  List<FileItem> _tree = [];

  @override
  void initState() {
    super.initState();
    adbService = ADBService();
    extractorService = MediaExtractorService();
  }

  /* =========================
     VERIFICAR CONEXIÓN
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
     CONSTRUIR ÁRBOL DE DIRECTORIOS
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
        .map((d) => FileItem(name: d, path: '$path/$d', children: []))
        .toList();
  }

  /* =========================
     CONSTRUIR ITEM DEL ÁRBOL
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
     INICIAR SCRCPY
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
          mode: ProcessStartMode.detachedWithStdio,
        );
        _showMessage('scrcpy iniciado');
      } else if (Platform.isLinux) {
        final homeDir = Platform.environment['HOME']!;
        final scrcpyPath = '$homeDir/scrcpy-linux-x86_64-v3.3.4/scrcpy';
        final file = File(scrcpyPath);

        if (!await file.exists()) {
          _showMessage('Error: scrcpy no encontrado en $scrcpyPath', error: true);
          return;
        }

        _showMessage('Verificando conexión ADB...');
        final adbResult = await Process.run('adb', ['devices']);
        print('ADB Devices: ${adbResult.stdout}');

        _showMessage('Iniciando scrcpy...');
        await Process.run('bash', [
          '-c',
          'cd "$homeDir/scrcpy-linux-x86_64-v3.3.4" && ./scrcpy --always-on-top --max-size=1920'
        ], runInShell: true);

        _showMessage('scrcpy ejecutado');
      }
    } catch (e) {
      _showMessage('Error: $e', error: true);
      print('Error detallado: $e');
    }
  }

  /* =========================
     EXTRAER ARCHIVOS DE HOY
     ========================= */
  Future<void> _extractTodayMedia() async {
    if (isDeviceConnected != true) {
      _showMessage('No hay dispositivo conectado', error: true);
      return;
    }

    setState(() => _loading = true);
    try {
      await extractorService.extractTodayMedia();
      _showMessage('Archivos de hoy extraídos correctamente');
    } catch (e) {
      _showMessage('Error: $e', error: true);
      print('Error detallado: $e');
    }
    setState(() => _loading = false);
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
          // Árbol de directorios (30%)
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

          // Panel de acciones (70%)
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
                    onPressed: (isDeviceConnected == true) ? _startScrcpy : null,
                    icon: const Icon(Icons.screen_share),
                    label: const Text('Iniciar scrcpy'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: (isDeviceConnected == true) ? _extractTodayMedia : null,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Extraer fotos de hoy'),
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
