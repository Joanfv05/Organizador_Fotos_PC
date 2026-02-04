import 'dart:io';
import 'package:path/path.dart' as path;
import '../adb/adb_service.dart';
import 'package:photo_organizer_pc/features/organizer/domain/models/transfer_progress.dart';

class MediaExtractorService {
  final ADBService adbService = ADBService();

  /// Extraer archivos de hoy desde la SD
  Future<void> extractTodayMedia({
    Function(TransferProgress)? onProgress,
    String? customLocalPath,
  }) async {
    final today = DateTime.now();
    await extractMediaFromDate(
      today,
      customLocalPath: customLocalPath,
      onProgress: onProgress,
    );
  }

  /// Extraer archivos de una fecha específica
  Future<void> extractMediaFromDate(
      DateTime date, {
        String? customLocalPath,
        bool preserveMetadata = true,
        Function(TransferProgress)? onProgress,
      }) async {
    final deviceConnected = await adbService.isDeviceConnected();
    if (!deviceConnected) {
      throw Exception('No hay dispositivo conectado');
    }

    final remoteDir = await adbService.detectSDCameraPath();
    if (remoteDir == null) {
      throw Exception('No se encontró la carpeta DCIM/Camera en la SD externa');
    }

    final localDir = customLocalPath != null
        ? Directory(customLocalPath)
        : Directory('.${path.separator}temp_${DateTime.now().millisecondsSinceEpoch}');

    if (!await localDir.exists()) {
      await localDir.create(recursive: true);
    }

    final files = await adbService.listFiles(remoteDir);
    if (files.isEmpty) {
      throw Exception('No hay archivos en la carpeta remota');
    }

    final dateStr = date.toString().substring(0, 10).replaceAll('-', '');
    final filteredFiles = <String>[];

    for (final filename in files) {
      final extension = path.extension(filename).toLowerCase();
      if (!_isMediaFile(extension)) continue;

      // Buscar fecha en el nombre del archivo
      final dateMatch = _extractDateFromFilename(filename);
      if (dateMatch == null) continue;

      if (dateMatch == dateStr) {
        filteredFiles.add(filename);
      }
    }

    print('📊 Encontrados ${filteredFiles.length} archivos para $dateStr');

    // Copiar archivos
    for (int i = 0; i < filteredFiles.length; i++) {
      final filename = filteredFiles[i];
      final remotePath = '$remoteDir/$filename';
      final localPath = path.join(localDir.path, filename);

      if (onProgress != null) {
        onProgress(TransferProgress(
          current: i + 1,
          total: filteredFiles.length,
          currentFile: filename,
          type: TransferType.pull,
          sourcePath: remotePath,
          destinationPath: localPath,
        ));
      }

      try {
        await adbService.pullFile(
          remotePath,
          localPath,
          preserveMetadata: preserveMetadata,
        );
        print('✅ $filename');
      } catch (e) {
        print('⚠️ $filename: $e');
      }

      await Future.delayed(Duration(milliseconds: 10));
    }

    print('🎉 ${filteredFiles.length} archivos copiados a: ${localDir.path}');
  }

  /// Extraer archivos de un mes específico
  Future<void> extractMediaFromMonth(
      int year,
      int month, {
        String? customLocalPath,
        bool preserveMetadata = true,
        Function(TransferProgress)? onProgress,
      }) async {
    final deviceConnected = await adbService.isDeviceConnected();
    if (!deviceConnected) {
      throw Exception('No hay dispositivo conectado');
    }

    final remoteDir = await adbService.detectSDCameraPath();
    if (remoteDir == null) {
      throw Exception('No se encontró la carpeta DCIM/Camera en la SD externa');
    }

    final localDir = customLocalPath != null
        ? Directory(customLocalPath)
        : Directory('.${path.separator}temp_${DateTime.now().millisecondsSinceEpoch}');

    if (!await localDir.exists()) {
      await localDir.create(recursive: true);
    }

    final files = await adbService.listFiles(remoteDir);
    if (files.isEmpty) {
      throw Exception('No hay archivos en la carpeta remota');
    }

    final monthStr = month.toString().padLeft(2, '0');
    final filteredFiles = <String>[];

    for (final filename in files) {
      final extension = path.extension(filename).toLowerCase();
      if (!_isMediaFile(extension)) continue;

      final dateMatch = _extractDateFromFilename(filename);
      if (dateMatch == null) continue;

      final fileYear = dateMatch.substring(0, 4);
      final fileMonth = dateMatch.substring(4, 6);

      if (fileYear == year.toString() && fileMonth == monthStr) {
        filteredFiles.add(filename);
      }
    }

    print('📊 Encontrados ${filteredFiles.length} archivos para $year-$monthStr');

    // Copiar archivos
    for (int i = 0; i < filteredFiles.length; i++) {
      final filename = filteredFiles[i];
      final remotePath = '$remoteDir/$filename';
      final localPath = path.join(localDir.path, filename);

      if (onProgress != null) {
        onProgress(TransferProgress(
          current: i + 1,
          total: filteredFiles.length,
          currentFile: filename,
          type: TransferType.pull,
          sourcePath: remotePath,
          destinationPath: localPath,
        ));
      }

      try {
        await adbService.pullFile(
          remotePath,
          localPath,
          preserveMetadata: preserveMetadata,
        );
        print('✅ $filename');
      } catch (e) {
        print('⚠️ $filename: $e');
      }

      await Future.delayed(Duration(milliseconds: 10));
    }

    print('🎉 ${filteredFiles.length} archivos copiados a: ${localDir.path}');
  }

  /// Restaurar archivos al dispositivo
  Future<void> restoreMediaToDevice(String localFolderPath) async {
    final deviceConnected = await adbService.isDeviceConnected();
    if (!deviceConnected) {
      throw Exception('No hay dispositivo conectado');
    }

    final targetPath = await adbService.detectSDCameraPath();
    if (targetPath == null) {
      throw Exception('No se encontró ninguna SD con carpeta DCIM/Camera');
    }

    final localPath = Directory(localFolderPath);
    if (!await localPath.exists()) {
      throw Exception('La carpeta local no existe');
    }

    final files = await localPath.list(recursive: true).where((e) => e is File).toList();
    int total = 0;

    for (final fileEntity in files) {
      final file = fileEntity as File;
      final relativePath = path.relative(file.path, from: localPath.path);
      final remotePath = '$targetPath/$relativePath'.replaceAll('\\', '/');

      final remoteDir = path.dirname(remotePath);
      await adbService.createRemoteDirectory(remoteDir);

      final result = await adbService.pushFile(file.path, remotePath,
          preserveMetadata: true);

      if (result.toLowerCase().contains('error')) {
        print('⚠️ ${path.basename(file.path)}: $result');
      } else {
        total++;
      }
    }

    print('🎉 $total archivos restaurados.');
  }

  // ============ MÉTODOS PRIVADOS ============

  bool _isMediaFile(String extension) {
    const mediaExtensions = ['.jpg', '.jpeg', '.png', '.mp4', '.mov', '.heic', '.avi', '.3gp'];
    return mediaExtensions.contains(extension);
  }

  String? _extractDateFromFilename(String filename) {
    // Patrones comunes: IMG_YYYYMMDD_HHMMSS.jpg, VID_YYYYMMDD_HHMMSS.mp4, YYYYMMDD_HHMMSS.jpg
    final patterns = [
      RegExp(r'(?:IMG|VID)_(\d{8})_\d{6}'),
      RegExp(r'(\d{8})_\d{6}'),
      RegExp(r'(\d{4}-\d{2}-\d{2})'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(filename);
      if (match != null) {
        String date = match.group(1)!;
        // Si tiene guiones, quitarlos
        return date.replaceAll('-', '');
      }
    }

    return null;
  }

  String _getMonthName(int month) {
    const monthNames = {
      1: 'Enero', 2: 'Febrero', 3: 'Marzo', 4: 'Abril',
      5: 'Mayo', 6: 'Junio', 7: 'Julio', 8: 'Agosto',
      9: 'Septiembre', 10: 'Octubre', 11: 'Noviembre', 12: 'Diciembre'
    };
    return monthNames[month] ?? 'Mes $month';
  }
}