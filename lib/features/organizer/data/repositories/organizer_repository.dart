import 'dart:io';
import 'package:photo_organizer_pc/core/adb/adb_service.dart';
import 'package:photo_organizer_pc/core/adb/media_extractor.dart';
import 'package:photo_organizer_pc/features/organizer/domain/models/file_item.dart';
import 'package:photo_organizer_pc/features/organizer/domain/models/transfer_progress.dart';

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
  Future<void> extractTodayMedia({
    Function(TransferProgress)? onProgress,
  }) async {
    await extractorService.extractTodayMedia(onProgress: onProgress);
  }

  // Copiar y organizar media
  Future<void> copyAndOrganizeMedia({
    Function(TransferProgress)? onProgress,
  }) async {
    final sdCameraPath = await adbService.detectSDCameraPath();
    if (sdCameraPath == null) {
      throw Exception('No se encontró la carpeta DCIM/Camera en la SD externa');
    }

    final localBackupDir = Directory('LocalBackup');
    await localBackupDir.create(recursive: true);

    // Obtener lista de archivos primero
    final files = await adbService.listFiles(sdCameraPath);

    // Filtrar solo archivos de media
    final mediaFiles = files.where((file) {
      final ext = file.toLowerCase();
      return ext.endsWith('.jpg') ||
          ext.endsWith('.jpeg') ||
          ext.endsWith('.png') ||
          ext.endsWith('.mp4') ||
          ext.endsWith('.mov') ||
          ext.endsWith('.heic');
    }).toList();

    // Copiar con progreso
    for (int i = 0; i < mediaFiles.length; i++) {
      final file = mediaFiles[i];
      final remotePath = '$sdCameraPath/$file';
      final localPath = '${localBackupDir.path}/$file';

      // Notificar progreso
      if (onProgress != null) {
        onProgress(TransferProgress(
          current: i + 1,
          total: mediaFiles.length,
          currentFile: file,
          type: TransferType.pull,
        ));
      }

      // Copiar archivo
      await adbService.pullFile(remotePath, localPath);

      // Pequeña pausa para no sobrecargar
      await Future.delayed(const Duration(milliseconds: 10));
    }

    // Organizar por mes
    await _organizeByMonth(localBackupDir.path, onProgress: onProgress);
  }

  // Método para organizar por mes
  Future<void> _organizeByMonth(String sourceDir,
      {Function(TransferProgress)? onProgress}) async {
    final sourceDirectory = Directory(sourceDir);
    final files = await sourceDirectory
        .list()
        .where((e) => e is File)
        .cast<File>()
        .toList();

    // Mapa de meses en español
    final meses = {
      1: 'Enero', 2: 'Febrero', 3: 'Marzo', 4: 'Abril',
      5: 'Mayo', 6: 'Junio', 7: 'Julio', 8: 'Agosto',
      9: 'Septiembre', 10: 'Octubre', 11: 'Noviembre', 12: 'Diciembre'
    };

    for (int i = 0; i < files.length; i++) {
      final file = files[i];
      final fileName = file.path.split('/').last;

      // Buscar fecha en formato: YYYYMMDD_HHMMSS
      final dateMatch = RegExp(r'(\d{4})(\d{2})(\d{2})_').firstMatch(fileName);

      if (dateMatch != null) {
        final year = dateMatch.group(1)!;
        final monthNum = int.parse(dateMatch.group(2)!);
        final monthName = meses[monthNum] ?? 'Desconocido';

        // Formato: "01 - Enero"
        final monthFolder = '${monthNum.toString().padLeft(2, '0')} - $monthName';
        final monthDir = Directory('$sourceDir/$year/$monthFolder');
        await monthDir.create(recursive: true);

        // Mover archivo
        final newPath = '${monthDir.path}/$fileName';
        await file.rename(newPath);
      }

      // Notificar progreso
      if (onProgress != null) {
        onProgress(TransferProgress(
          current: i + 1,
          total: files.length,
          currentFile: 'Organizando: $fileName',
          type: TransferType.organizing,
        ));
      }
    }
  }

  // Métodos privados
  Future<List<FileItem>> _loadDirectories(String path) async {
    final dirs = await adbService.listDirectories(path);
    return dirs
        .map((d) => FileItem(name: d, path: '$path/$d', children: []))
        .toList();
  }
}