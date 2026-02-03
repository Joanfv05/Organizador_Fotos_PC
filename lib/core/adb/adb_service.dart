import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;

class ADBService {
  // =========================
  // CONFIGURACIÓN REUTILIZABLE
  // =========================
  static const Map<int, String> mesesEs = {
    1: 'Enero', 2: 'Febrero', 3: 'Marzo', 4: 'Abril',
    5: 'Mayo', 6: 'Junio', 7: 'Julio', 8: 'Agosto',
    9: 'Septiembre', 10: 'Octubre', 11: 'Noviembre', 12: 'Diciembre',
  };

  static const List<String> mediaExtensions = [
    '.jpg', '.jpeg', '.png', '.mp4', '.mov', '.heic', '.avi', '.3gp'
  ];

  static const String filenameDateRegex = r'(?:[A-Z]+_)?(\d{8})_\d{6}.*';

  // =========================
  // ADB DISPONIBILIDAD
  // =========================
  static Future<bool> get isAdbAvailable async {
    try {
      final result = await Process.run(
        Platform.isWindows ? 'where' : 'which',
        ['adb'],
      );
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  // =========================
  // CONEXIÓN DISPOSITIVO
  // =========================
  Future<bool> isDeviceConnected() async {
    try {
      final adb = await _resolveAdb();
      final result = await Process.run(adb, ['devices']);
      return _parseAdbDevices(result.stdout.toString());
    } catch (_) {
      return false;
    }
  }

  bool _parseAdbDevices(String output) {
    final lines = output.split('\n');
    for (var line in lines) {
      line = line.trim();
      if (line.isNotEmpty && !line.startsWith('List of devices')) {
        if (line.contains('\tdevice')) {
          return true;
        }
      }
    }
    return false;
  }

  // =========================
  // DETECTAR RUTA SD CARD CON DCIM/CAMERA
  // =========================
  Future<String?> detectSDCameraPath() async {
    try {
      final storageDirs = await listDirectories('/storage');
      for (final dir in storageDirs) {
        if (RegExp(r'^[A-Z0-9]{4}-[A-Z0-9]{4}$').hasMatch(dir)) {
          final potentialPath = '/storage/$dir/DCIM/Camera';
          final exists = await checkDirectoryExists(potentialPath);
          if (exists) return potentialPath;
        }
      }
    } catch (e) {
      print('Error detectando SD: $e');
    }
    return null;
  }

  // =========================
  // LISTAR SOLO CARPETAS
  // =========================
  Future<List<String>> listDirectories(String directoryPath) async {
    try {
      final adb = await _resolveAdb();
      final result = await Process.run(
        adb,
        ['shell', 'ls', '-p', directoryPath],
      );

      if (result.exitCode != 0) return [];

      return result.stdout
          .toString()
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.endsWith('/'))
          .map((e) => e.substring(0, e.length - 1))
          .where((e) => e.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  // =========================
  // LISTAR ARCHIVOS EN DIRECTORIO
  // =========================
  Future<List<String>> listFiles(String directoryPath) async {
    try {
      final adb = await _resolveAdb();
      final result = await Process.run(
        adb,
        ['shell', 'ls', directoryPath],
      );

      if (result.exitCode != 0) return [];

      return result.stdout
          .toString()
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  // =========================
  // VERIFICAR SI UN DIRECTORIO EXISTE
  // =========================
  Future<bool> checkDirectoryExists(String directoryPath) async {
    try {
      final adb = await _resolveAdb();
      final result = await Process.run(
        adb,
        ['shell', 'test', '-d', directoryPath, '&&', 'echo', 'exists'],
      );
      return result.stdout.toString().contains('exists');
    } catch (_) {
      return false;
    }
  }

  // =========================
  // EJECUTAR COMANDO ADB GENÉRICO
  // =========================
  Future<String> runAdbCommand(List<String> args) async {
    try {
      final adb = await _resolveAdb();
      final result = await Process.run(adb, args);
      return result.stdout.toString();
    } catch (e) {
      return 'Error: $e';
    }
  }

  // =========================
  // PULL DE ARCHIVOS CON METADATOS
  // =========================
  Future<String> pullFile(String remotePath, String localPath,
      {bool preserveMetadata = true}) async {
    try {
      final adb = await _resolveAdb();
      final args = ['pull'];
      if (preserveMetadata) args.add('-a');
      args.addAll([remotePath, localPath]);

      final result = await Process.run(adb, args);
      return result.stdout.toString();
    } catch (e) {
      return 'Error: $e';
    }
  }

  // =========================
  // PUSH DE ARCHIVOS CON METADATOS
  // =========================
  Future<String> pushFile(String localPath, String remotePath,
      {bool preserveMetadata = true}) async {
    try {
      final adb = await _resolveAdb();
      final args = ['push'];
      if (preserveMetadata) args.add('-a');
      args.addAll([localPath, remotePath]);

      final result = await Process.run(adb, args);
      return result.stdout.toString();
    } catch (e) {
      return 'Error: $e';
    }
  }

  // =========================
  // CREAR DIRECTORIO EN DISPOSITIVO
  // =========================
  Future<String> createRemoteDirectory(String remotePath) async {
    try {
      final adb = await _resolveAdb();
      final result = await Process.run(adb, ['shell', 'mkdir', '-p', remotePath]);
      return result.stdout.toString();
    } catch (e) {
      return 'Error: $e';
    }
  }

  // =========================
  // DETECTAR RUTAS WHATSAPP
  // =========================
  Future<List<String>> detectWhatsAppPaths() async {
    final List<String> waPaths = [
      '/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/WhatsApp Images',
      '/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/WhatsApp Video',
    ];

    final List<String> existingPaths = [];
    for (final path in waPaths) {
      if (await checkDirectoryExists(path)) {
        existingPaths.add(path);
      }
    }
    return existingPaths;
  }

  // =========================
  // RESOLVER ADB (Método interno) - VERSIÓN UNIFICADA
  // =========================
  Future<String> _resolveAdb() async {
    // 1. Primero intentar ADB del sistema (opcional)
    if (await isAdbAvailable) {
      return 'adb';
    }

    // 2. Buscar en external/adb/ según plataforma
    final externalPath = await _findExternalAdb();
    if (externalPath != null) {
      return externalPath;
    }

    throw Exception('ADB no disponible en external/adb/');
  }

  // ============ BUSCAR ADB EN EXTERNAL/ PARA AMBAS PLATAFORMAS ============
  Future<String?> _findExternalAdb() async {
    final currentDir = Directory.current.path;

    if (Platform.isWindows) {
      // Windows: external/adb/windows/adb.exe
      final windowsPath = path.join(currentDir, 'external', 'adb', 'windows', 'adb.exe');
      final windowsFile = File(windowsPath);

      if (await windowsFile.exists()) {
        return windowsPath;
      }

      // Backup: buscar junto al ejecutable (para releases)
      try {
        final executablePath = Platform.resolvedExecutable;
        final executableDir = File(executablePath).parent;
        final releasePath = path.join(executableDir.path, 'adb', 'windows', 'adb.exe');
        final releaseFile = File(releasePath);

        if (await releaseFile.exists()) {
          return releasePath;
        }
      } catch (e) {
        // Ignorar error
      }

    } else {
      // Linux: external/adb/linux/adb
      final linuxPath = path.join(currentDir, 'external', 'adb', 'linux', 'adb');
      final linuxFile = File(linuxPath);

      if (await linuxFile.exists()) {
        // Dar permisos de ejecución
        await Process.run('chmod', ['+x', linuxPath]);
        return linuxPath;
      }
    }

    return null;
  }

  // ============ MÉTODOS DEPRECADOS (se pueden eliminar eventualmente) ============
  // Estos métodos ya no son necesarios porque usamos external/,
  // pero los mantengo por compatibilidad

  Future<bool> _hasAssetAdb() async {
    try {
      final assetPath = Platform.isWindows
          ? 'assets/adb/windows/adb.exe'
          : 'assets/adb/linux/adb';
      await rootBundle.load(assetPath);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String> _getAssetAdbPath() async {
    final assetPath = Platform.isWindows
        ? 'assets/adb/windows/adb.exe'
        : 'assets/adb/linux/adb';

    final bytes = await rootBundle.load(assetPath);
    final tempDir = await Directory.systemTemp.createTemp('adb_');
    final adbFile = File(
      path.join(tempDir.path, Platform.isWindows ? 'adb.exe' : 'adb'),
    );

    await adbFile.writeAsBytes(bytes.buffer.asUint8List());

    if (!Platform.isWindows) {
      await Process.run('chmod', ['+x', adbFile.path]);
    }

    return adbFile.path;
  }
}