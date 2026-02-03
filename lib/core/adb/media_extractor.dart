// media_extractor.dart
import 'dart:io';
import 'package:path/path.dart' as path;
import '../adb/adb_service.dart';
import 'package:photo_organizer_pc/features/organizer/domain/models/transfer_progress.dart';

class MediaExtractorService {
  final ADBService adbService = ADBService();

  // Reutilizar constantes de ADBService en lugar de duplicar
  List<String> get _mediaExtensions => ADBService.mediaExtensions;
  Map<int, String> get _monthsEs => ADBService.mesesEs;
  String get _dateRegex => ADBService.filenameDateRegex;

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

    final dateStr = date.toString().substring(0, 10).replaceAll('-', '');
    final folderName = date.toString().substring(0, 10);
    final localDir = customLocalPath != null
        ? Directory(customLocalPath)
        : await _createBackupDir(folderName);

    print('📁 Creando carpeta para fecha específica: ${localDir.path}');

    if (!await localDir.exists()) {
      await localDir.create(recursive: true);
    }

    final files = await adbService.listFiles(remoteDir);
    if (files.isEmpty) {
      throw Exception('No hay archivos en la carpeta remota');
    }

    final regex = RegExp(_dateRegex);

    // Filtrar archivos de la fecha específica
    final filteredFiles = <String>[];
    for (final filename in files) {
      final extension = path.extension(filename).toLowerCase();
      if (!_mediaExtensions.contains(extension)) continue;

      final match = regex.firstMatch(filename);
      if (match == null) continue;

      final fileDate = match.group(1);
      if (fileDate == dateStr) {
        filteredFiles.add(filename);
      }
    }

    print('📊 Archivos encontrados para la fecha $dateStr: ${filteredFiles.length}');

    // Copiar archivos con progreso
    for (int i = 0; i < filteredFiles.length; i++) {
      final filename = filteredFiles[i];
      final remotePath = '$remoteDir/$filename';
      final localPath = path.join(localDir.path, filename);

      // Notificar progreso
      if (onProgress != null) {
        onProgress(TransferProgress(
          current: i + 1,
          total: filteredFiles.length,
          currentFile: filename,
          type: TransferType.pull,
        ));
      }

      final result = await adbService.pullFile(
        remotePath,
        localPath,
        preserveMetadata: preserveMetadata,
      );

      if (result.contains('Error')) {
        print('⚠️ Error extrayendo $filename: $result');
      } else {
        print('✅ $filename copiado a: $localPath');
      }

      // Pequeña pausa
      await Future.delayed(const Duration(milliseconds: 10));
    }

    print('\n🎉 Proceso completado. ${filteredFiles.length} archivos copiados.');
    print('📁 Carpeta destino: ${localDir.path}');
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

    final monthStr = month.toString().padLeft(2, '0');
    final folderName = customLocalPath ??
        '$year-${monthStr}_${preserveMetadata ? 'METADATA_OK' : ''}';

    final localDir = await _createBackupDir(folderName);

    print('📁 Creando carpeta para mes específico: ${localDir.path}');

    if (!await localDir.exists()) {
      await localDir.create(recursive: true);
    }

    final files = await adbService.listFiles(remoteDir);
    if (files.isEmpty) {
      throw Exception('No hay archivos en la carpeta remota');
    }

    final regex = RegExp(_dateRegex);

    // Filtrar archivos del mes específico
    final filteredFiles = <String>[];
    for (final filename in files) {
      final extension = path.extension(filename).toLowerCase();
      if (!_mediaExtensions.contains(extension)) continue;

      final match = regex.firstMatch(filename);
      if (match == null) continue;

      final fileDate = match.group(1)!;
      final fileYear = fileDate.substring(0, 4);
      final fileMonth = fileDate.substring(4, 6);

      if (fileYear == year.toString() && fileMonth == monthStr) {
        filteredFiles.add(filename);
      }
    }

    print('📊 Archivos encontrados para $year-$monthStr: ${filteredFiles.length}');

    // Copiar con progreso
    for (int i = 0; i < filteredFiles.length; i++) {
      final filename = filteredFiles[i];
      final remotePath = '$remoteDir/$filename';
      final localPath = path.join(localDir.path, filename);

      // Notificar progreso
      if (onProgress != null) {
        onProgress(TransferProgress(
          current: i + 1,
          total: filteredFiles.length,
          currentFile: filename,
          type: TransferType.pull,
        ));
      }

      final result = await adbService.pullFile(
        remotePath,
        localPath,
        preserveMetadata: preserveMetadata,
      );

      if (result.contains('Error')) {
        print('⚠️ Error extrayendo $filename: $result');
        continue;
      }

      print('✅ $filename copiado a: $localPath');

      // Pequeña pausa
      await Future.delayed(const Duration(milliseconds: 10));
    }

    print('\n🎉 Proceso completado. ${filteredFiles.length} archivos copiados.');
    print('📁 Carpeta destino: ${localDir.path}');
  }

  /// Extraer y organizar archivos de WhatsApp
  Future<void> extractAndOrganizeWhatsAppMedia(
      {String localDirName = 'WhatsApp Media'}) async {
    final deviceConnected = await adbService.isDeviceConnected();
    if (!deviceConnected) {
      throw Exception('No hay dispositivo conectado');
    }

    final waPaths = await adbService.detectWhatsAppPaths();
    if (waPaths.isEmpty) {
      throw Exception('No se encontraron carpetas de WhatsApp');
    }

    final localDir = await _createBackupDir(localDirName);

    print('📁 Creando carpeta para WhatsApp: ${localDir.path}');

    if (!await localDir.exists()) {
      await localDir.create(recursive: true);
    }

    // Copiar contenido de cada ruta de WhatsApp
    for (final remotePath in waPaths) {
      print('📥 Copiando archivos desde $remotePath...');
      final result = await adbService.runAdbCommand(['pull', remotePath, localDir.path]);
      print('Resultado: $result');
    }

    // Organizar por mes
    await _organizeWhatsAppFilesByMonth(localDir);

    print('✅ WhatsApp organizado en: ${localDir.path}');
  }

  /// Organizar archivos de WhatsApp por mes
  Future<void> _organizeWhatsAppFilesByMonth(Directory sourceDir) async {
    final filesToMove = <File>[];

    await for (var entity in sourceDir.list(recursive: true)) {
      if (entity is File &&
          _mediaExtensions.contains(path.extension(entity.path).toLowerCase())) {
        filesToMove.add(entity);
      }
    }

    print('📊 Organizando ${filesToMove.length} archivos de WhatsApp...');

    for (final file in filesToMove) {
      // Ignorar archivos de papelera de WhatsApp
      if (path.basename(file.path).startsWith('.trashed-')) {
        continue;
      }

      final fileName = path.basenameWithoutExtension(file.path);
      final regex = RegExp(r'(?:IMG|VID)-(\d{4})(\d{2})(\d{2})-WA\d+');
      final match = regex.firstMatch(fileName);

      Directory destinationDir;

      if (match != null) {
        final year = match.group(1)!;
        final monthNumber = int.parse(match.group(2)!);
        final monthName = _monthsEs[monthNumber]!;
        final folderName = '${monthNumber.toString().padLeft(2, '0')}-$monthName';
        destinationDir = Directory(path.join(sourceDir.path, folderName));
      } else {
        destinationDir = Directory(path.join(sourceDir.path, 'SinFecha'));
      }

      if (!await destinationDir.exists()) {
        await destinationDir.create(recursive: true);
      }

      var newPath = path.join(destinationDir.path, path.basename(file.path));
      var counter = 1;

      while (await File(newPath).exists()) {
        newPath = path.join(destinationDir.path,
            '${fileName}_$counter${path.extension(file.path)}');
        counter++;
      }

      await file.rename(newPath);
      print('📂 Movido: ${path.basename(file.path)} → ${path.relative(newPath, from: sourceDir.path)}');
    }

    print('✅ WhatsApp organizado por mes.');
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

    print('⏳ Copiando archivos a la SD...');

    final files = await localPath.list(recursive: true).where((e) => e is File).toList();
    int total = 0;

    for (final fileEntity in files) {
      final file = fileEntity as File;
      final relativePath = path.relative(file.path, from: localPath.path);
      final remotePath = '$targetPath/$relativePath'.replaceAll('\\', '/');

      // Crear carpeta remota si no existe
      final remoteDir = path.dirname(remotePath);
      await adbService.createRemoteDirectory(remoteDir);

      // Subir el archivo manteniendo metadatos
      final result = await adbService.pushFile(file.path, remotePath,
          preserveMetadata: true);

      if (result.toLowerCase().contains('error')) {
        print('⚠️ Error subiendo ${file.path}: $result');
      } else {
        print('✅ ${path.basename(file.path)} restaurado.');
        total++;
      }
    }

    print('\n🎉 Restauración completada. $total archivos subidos.');
  }

  // ============ MÉTODO PRIVADO PARA CREAR CARPETAS ============
  Future<Directory> _createBackupDir(String folderName) async {
    final currentDir = Directory.current;

    // Si estamos en /lib/, subir 2 niveles para llegar a la raíz del proyecto
    if (currentDir.path.endsWith('/lib')) {
      final projectRoot = Directory(path.join(currentDir.path, '..', '..'));
      final rootPath = projectRoot.absolute.path;
      final targetDir = Directory(path.join(rootPath, folderName));

      print('📍 Detectado directorio /lib/, usando raíz del proyecto:');
      print('   - Actual: ${currentDir.path}');
      print('   - Raíz: $rootPath');
      print('   - Destino: ${targetDir.path}');

      return targetDir;
    } else {
      // No estamos en /lib/, usar directorio actual
      final targetDir = Directory(path.join(currentDir.path, folderName));

      print('📍 Usando directorio actual:');
      print('   - Actual: ${currentDir.path}');
      print('   - Destino: ${targetDir.path}');

      return targetDir;
    }
  }
}