import 'dart:io';
import 'package:photo_organizer_pc/core/adb/adb_service.dart';
import 'package:photo_organizer_pc/core/adb/media_extractor.dart';
import 'package:photo_organizer_pc/features/organizer/domain/models/file_item.dart';

class OrganizerRepository {
  final ADBService adbService;
  final MediaExtractorService extractorService;

  OrganizerRepository({
    required this.adbService,
    required this.extractorService,
  });

  // Conexión
  Future<bool> checkDeviceConnection() async {
    return await adbService.isDeviceConnected();
  }

  // Árbol de directorios
  Future<List<FileItem>> buildRootTree() async {
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

    // SD externa
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
      // Ignorar errores
    }

    return roots;
  }

  Future<List<FileItem>> loadDirectories(String path) async {
    final dirs = await adbService.listDirectories(path);
    return dirs
        .map((d) => FileItem(name: d, path: '$path/$d', children: []))
        .toList();
  }

  // Scrcpy
  Future<void> startScrcpy() async {
    if (Platform.isWindows) {
      await Process.start(
        'assets/adb/windows/scrcpy.exe',
        [],
        mode: ProcessStartMode.detachedWithStdio,
      );
    } else if (Platform.isLinux) {
      final homeDir = Platform.environment['HOME']!;
      final scrcpyPath = '$homeDir/scrcpy-linux-x86_64-v3.3.4/scrcpy';
      final file = File(scrcpyPath);

      if (!await file.exists()) {
        throw Exception('scrcpy no encontrado en $scrcpyPath');
      }

      await Process.run('bash', [
        '-c',
        'cd "$homeDir/scrcpy-linux-x86_64-v3.3.4" && ./scrcpy --always-on-top --max-size=1920'
      ], runInShell: true);
    }
  }

  // Extracción de media
  Future<void> extractTodayMedia() async {
    await extractorService.extractTodayMedia();
  }

  // Copiar y organizar media
  Future<void> copyAndOrganizeMedia() async {
    final sdCameraPath = await adbService.detectSDCameraPath();
    if (sdCameraPath == null) {
      throw Exception('No se encontró la carpeta DCIM/Camera en la SD externa');
    }

    final localBackupDir = Directory('LocalBackup');
    await localBackupDir.create(recursive: true);

    await adbService.runAdbCommand(['pull', sdCameraPath, localBackupDir.path]);
  }

  // Métodos privados
  Future<List<FileItem>> _loadDirectories(String path) async {
    final dirs = await adbService.listDirectories(path);
    return dirs
        .map((d) => FileItem(name: d, path: '$path/$d', children: []))
        .toList();
  }
}