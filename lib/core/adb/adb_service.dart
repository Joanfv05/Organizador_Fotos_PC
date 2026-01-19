import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;

class ADBService {
  /* =========================
     ADB DISPONIBILIDAD
     ========================= */

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

  /* =========================
     CONEXIÓN DISPOSITIVO
     ========================= */

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

  /* =========================
     LISTAR SOLO CARPETAS
     ========================= */

  /// Devuelve SOLO directorios usando `ls -p`
  /// En Android, las carpetas terminan en `/`
  Future<List<String>> listDirectories(String directoryPath) async {
    try {
      final adb = await _resolveAdb();

      final result = await Process.run(
        adb,
        ['shell', 'ls', '-p', directoryPath],
      );

      if (result.exitCode != 0) {
        return [];
      }

      return result.stdout
          .toString()
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.endsWith('/')) // SOLO carpetas
          .map((e) => e.substring(0, e.length - 1)) // quitar /
          .where((e) => e.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  /* =========================
     RESOLVER ADB
     ========================= */

  Future<String> _resolveAdb() async {
    // 1. ADB del sistema
    if (await isAdbAvailable) {
      return 'adb';
    }

    // 2. ADB en assets
    if (await _hasAssetAdb()) {
      return await _getAssetAdbPath();
    }

    throw Exception('ADB no disponible');
  }

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
