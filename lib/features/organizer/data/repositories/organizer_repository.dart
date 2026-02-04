import 'dart:io';
import 'package:photo_organizer_pc/core/adb/adb_service.dart';
import 'package:photo_organizer_pc/core/adb/media_extractor.dart';
import 'package:photo_organizer_pc/features/organizer/domain/models/file_item.dart';
import 'package:photo_organizer_pc/features/organizer/domain/models/transfer_progress.dart';
import 'package:path/path.dart' as path;

class OrganizerRepository {
  final ADBService adbService;
  final MediaExtractorService extractorService;

  // Expresiones regulares reutilizables
  static final _storageDirRegex = RegExp(r'^[A-Z0-9]{4}-[A-Z0-9]{4}$');
  static final _dateRegex = RegExp(r'(?:[A-Z]+_)?(\d{4})(\d{2})(\d{2})_\d{6}.*');
  static final _dateOnlyRegex = RegExp(r'(?:[A-Z]+_)?(\d{8})_\d{6}.*');

  // Extensiones de media
  static const _mediaExtensions = ['.jpg', '.jpeg', '.png', '.mp4', '.mov', '.heic'];

  // Meses en español
  static const _months = {
    1: 'Enero', 2: 'Febrero', 3: 'Marzo', 4: 'Abril',
    5: 'Mayo', 6: 'Junio', 7: 'Julio', 8: 'Agosto',
    9: 'Septiembre', 10: 'Octubre', 11: 'Noviembre', 12: 'Diciembre'
  };

  OrganizerRepository({
    required this.adbService,
    required this.extractorService,
  });

  // ============ CONEXIÓN ============
  Future<bool> checkDeviceConnection() async {
    return await adbService.isDeviceConnected();
  }

  // ============ ÁRBOL DE DIRECTORIOS ============
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
        if (_storageDirRegex.hasMatch(dir)) {
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
    return await _loadDirectories(path);
  }

  // ============ SCRCPY ============
  Future<void> startScrcpy() async {
    final currentDir = Directory.current.path;

    if (Platform.isWindows) {
      // Windows: external/adb/windows/scrcpy.exe
      final scrcpyPath = path.join(currentDir, 'external', 'adb', 'windows', 'scrcpy.exe');
      await _startScrcpyWithPath(scrcpyPath, ['--always-on-top', '--max-size=1920']);
    } else if (Platform.isLinux) {
      // Linux: external/adb/linux/scrcpy
      final scrcpyPath = path.join(currentDir, 'external', 'adb', 'linux', 'scrcpy');
      await _startScrcpyWithPath(scrcpyPath, ['--always-on-top', '--max-size=1920']);
    }
  }

  Future<void> _startScrcpyWithPath(String scrcpyPath, List<String> args) async {
    final scrcpyFile = File(scrcpyPath);

    if (!await scrcpyFile.exists()) {
      throw Exception('scrcpy no encontrado en: $scrcpyPath');
    }

    // Dar permisos de ejecución en Linux
    if (!Platform.isWindows) {
      await Process.run('chmod', ['+x', scrcpyPath]);
    }

    if (Platform.isWindows) {
      await Process.start(
        scrcpyPath,
        args,
        mode: ProcessStartMode.detachedWithStdio,
      );
    } else {
      // Linux: ejecutar directamente en su directorio y conectarse al servidor X
      final scrcpyDir = Directory(path.dirname(scrcpyPath));

      // Importante: no detached, sí stdio heredado para que se abra la ventana
      await Process.start(
        scrcpyPath,
        args,
        workingDirectory: scrcpyDir.path,
        mode: ProcessStartMode.inheritStdio,
      );
    }
  }

  // ============ EXTRACCIÓN DE MEDIA ============
  Future<void> extractTodayMedia({
    Function(TransferProgress)? onProgress,
  }) async {
    final today = DateTime.now();
    final folderName = 'Fotos_${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final destinationDir = await _createLocalBackupDir(folderName);

    await extractorService.extractMediaFromDate(
      today,
      customLocalPath: destinationDir.path,
      onProgress: onProgress,
    );
  }

  // ============ COPIA Y ORGANIZACIÓN ============
  Future<void> copyAndOrganizeMedia({
    required int year,
    Function(TransferProgress)? onProgress,
  }) async {
    print('=== INICIANDO copyAndOrganizeMedia($year) ===');

    final sdCameraPath = await _getSdCameraPathOrThrow();
    print('📁 SD Camera Path: $sdCameraPath');

    final localBackupDir = await _createLocalBackupDir('Fotos_$year');
    print('📁 Local Backup Dir: ${localBackupDir.path}');

    final files = await adbService.listFiles(sdCameraPath);
    print('📊 Archivos en SD: ${files.length}');

    final mediaFiles = _filterFilesByYear(files, year);
    print('📊 Archivos del año $year: ${mediaFiles.length}');

    if (mediaFiles.isEmpty) {
      throw Exception('No se encontraron fotos o vídeos para el año $year');
    }

    await _copyFilesWithProgress(
      files: mediaFiles,
      sourceDir: sdCameraPath,
      destinationDir: localBackupDir,
      onProgress: onProgress,
    );

    await _organizeByMonth(localBackupDir.path, onProgress: onProgress);
  }

  Future<void> copyMediaByMonth({
    required int year,
    required int month,
    Function(TransferProgress)? onProgress,
  }) async {
    print('=== INICIANDO copyMediaByMonth($year, $month) ===');

    final sdCameraPath = await _getSdCameraPathOrThrow();
    final monthStr = month.toString().padLeft(2, '0');
    final monthName = _months[month] ?? 'Mes $month';
    final localBackupDir = await _createLocalBackupDir('Fotos_$year-$monthStr-$monthName');

    print('📁 Local Backup Dir: ${localBackupDir.path}');

    final files = await adbService.listFiles(sdCameraPath);
    final monthFiles = _filterFilesByMonth(files, year, month);

    if (monthFiles.isEmpty) {
      throw Exception('No se encontraron fotos o vídeos para $year-$monthStr');
    }

    await _copyFilesWithProgress(
      files: monthFiles,
      sourceDir: sdCameraPath,
      destinationDir: localBackupDir,
      onProgress: onProgress,
    );
  }

  // ============ BÚSQUEDA POR FECHA ============
  Future<void> extractMediaFromSpecificDate(
      DateTime date, {
        Function(TransferProgress)? onProgress,
      }) async {
    final folderName = 'Fotos_${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final destinationDir = await _createLocalBackupDir(folderName);

    await extractorService.extractMediaFromDate(
      date,
      customLocalPath: destinationDir.path,
      onProgress: onProgress,
    );
  }

  Future<List<String>> findFilesByDate(DateTime date) async {
    final sdCameraPath = await _getSdCameraPathOrThrow();
    final files = await adbService.listFiles(sdCameraPath);
    final dateStr = date.toString().substring(0, 10).replaceAll('-', '');

    return files.where((filename) {
      final match = _dateOnlyRegex.firstMatch(filename);
      if (match == null) return false;
      final fileDate = match.group(1);
      return fileDate == dateStr;
    }).toList();
  }

  // ============ MÉTODOS PRIVADOS REUTILIZABLES ============
  Future<List<FileItem>> _loadDirectories(String path) async {
    final dirs = await adbService.listDirectories(path);
    return dirs
        .map((d) => FileItem(name: d, path: '$path/$d', children: []))
        .toList();
  }

  Future<String> _getSdCameraPathOrThrow() async {
    final sdCameraPath = await adbService.detectSDCameraPath();
    if (sdCameraPath == null) {
      throw Exception('No se encontró la carpeta DCIM/Camera en la SD externa');
    }
    return sdCameraPath;
  }

  Future<Directory> _createLocalBackupDir(String folderName) async {
    try {
      final currentDir = Directory.current;
      final projectRoot = Directory(path.join(currentDir.path, '..', '..'));
      final projectRootPath = projectRoot.absolute.path;

      // Verificar que estamos en la estructura correcta
      final isLibDir = currentDir.path.endsWith('/lib');

      Directory targetDir;

      if (isLibDir) {
        // Estamos en /lib/, usar raíz del proyecto
        targetDir = Directory(path.join(projectRootPath, folderName));
        print('📍 Creando en RAÍZ del proyecto: ${targetDir.path}');
      } else {
        // No estamos en /lib/, usar directorio actual
        targetDir = Directory(path.join(currentDir.path, folderName));
        print('📍 Creando en DIRECTORIO ACTUAL: ${targetDir.path}');
      }

      await targetDir.create(recursive: true);
      print('✅ Carpeta creada exitosamente: ${targetDir.path}');

      return targetDir;

    } catch (e) {
      print('🔴 Error creando carpeta: $e');

      // Fallback definitivo: HOME del usuario
      final homeDir = Platform.environment['HOME'] ?? '';
      if (homeDir.isEmpty) {
        throw Exception('No se pudo determinar el directorio HOME');
      }

      final fallbackDir = Directory(path.join(homeDir, 'Fotos Organizadas', folderName));

      print('🔄 Usando fallback: ${fallbackDir.path}');
      await fallbackDir.create(recursive: true);

      return fallbackDir;
    }
  }

  List<String> _filterFilesByYear(List<String> files, int year) {
    final yearStr = year.toString();
    return files.where((file) {
      if (!_isMediaFile(file)) return false;
      final match = _dateRegex.firstMatch(file);
      return match != null && match.group(1) == yearStr;
    }).toList();
  }

  List<String> _filterFilesByMonth(List<String> files, int year, int month) {
    final yearStr = year.toString();
    final monthStr = month.toString().padLeft(2, '0');

    return files.where((file) {
      if (!_isMediaFile(file)) return false;
      final match = _dateRegex.firstMatch(file);
      if (match == null) return false;
      return match.group(1) == yearStr && match.group(2) == monthStr;
    }).toList();
  }

  bool _isMediaFile(String filename) {
    final ext = path.extension(filename).toLowerCase();
    return _mediaExtensions.contains(ext);
  }

  Future<void> _copyFilesWithProgress({
    required List<String> files,
    required String sourceDir,
    required Directory destinationDir,
    required Function(TransferProgress)? onProgress,
  }) async {
    print('📥 Copiando ${files.length} archivos...');

    for (int i = 0; i < files.length; i++) {
      final file = files[i];
      final remotePath = '$sourceDir/$file';
      final localPath = path.join(destinationDir.path, file);

      // Detectar si es video para manejo especial
      final isVideo = file.toLowerCase().endsWith('.mp4') ||
          file.toLowerCase().endsWith('.mov') ||
          file.toLowerCase().endsWith('.avi');

      if (isVideo) {
        print('🎥 Procesando video: $file');
      }

      if (onProgress != null) {
        onProgress(TransferProgress(
          current: i + 1,
          total: files.length,
          currentFile: file,
          type: TransferType.pull,
          sourcePath: remotePath,
          destinationPath: localPath,
        ));
      }

      // Pausa más larga para videos grandes
      if (isVideo) {
        await Future.delayed(Duration(milliseconds: 100));
      }

      try {
        await adbService.pullFile(remotePath, localPath);

        // Verificar integridad del archivo copiado
        if (isVideo) {
          await _verifyFileIntegrity(localPath, file);
        }

      } catch (e) {
        print('⚠️ Error copiando $file: $e');
        // Continuar con el siguiente archivo
      }

      await Future.delayed(Duration(milliseconds: 50));
    }
  }

  Future<void> _verifyFileIntegrity(String localPath, String fileName) async {
    try {
      final file = File(localPath);
      if (await file.exists()) {
        final size = await file.length();
        print('✅ Video $fileName: ${(size / 1024 / 1024).toStringAsFixed(2)} MB');

        // Verificación básica para videos
        if (fileName.toLowerCase().endsWith('.mp4')) {
          try {
            final bytes = await file.readAsBytes();
            if (bytes.length > 8) {
              // Verificar header MP4 (debe empezar con 'ftyp')
              final header = String.fromCharCodes(bytes.sublist(4, 8));
              if (header == 'ftyp') {
                print('   ✅ Header MP4 válido');
              } else {
                print('   ⚠️ Header MP4 no válido: $header');
              }
            }
          } catch (e) {
            print('   🔴 Error leyendo bytes del video: $e');
          }
        }
      }
    } catch (e) {
      print('   🔴 Error verificando $fileName: $e');
    }
  }

  Future<String> getBackupDirectoryPath(String folderName) async {
    final dir = await _createLocalBackupDir(folderName);
    return dir.path;
  }

  Future<void> _organizeByMonth(String sourceDir,
      {Function(TransferProgress)? onProgress}) async {
    final sourceDirectory = Directory(sourceDir);

    try {
      final files = await sourceDirectory
          .list()
          .where((e) => e is File)
          .cast<File>()
          .toList();

      for (int i = 0; i < files.length; i++) {
        final file = files[i];
        final fileName = path.basename(file.path);
        final dateMatch = _dateRegex.firstMatch(fileName);

        if (dateMatch != null) {
          final year = dateMatch.group(1)!;
          final monthNum = int.parse(dateMatch.group(2)!);
          final monthName = _months[monthNum] ?? 'Desconocido';

          final monthFolder = '${monthNum.toString().padLeft(2, '0')} - $monthName';
          final monthDir = Directory(path.join(sourceDir, year, monthFolder));
          await monthDir.create(recursive: true);

          final newPath = path.join(monthDir.path, fileName);
          await file.rename(newPath);

          if (onProgress != null) {
            onProgress(TransferProgress(
              current: i + 1,
              total: files.length,
              currentFile: 'Organizando: $fileName',
              type: TransferType.organizing,
              destinationPath: path.join(sourceDir, year, monthFolder),
            ));
          }
        } else {
          if (onProgress != null) {
            onProgress(TransferProgress(
              current: i + 1,
              total: files.length,
              currentFile: 'Saltando (sin fecha): $fileName',
              type: TransferType.organizing,
            ));
          }
        }
      }
    } catch (e) {
      print('🔴 Error organizando archivos por mes: $e');
      throw Exception('Error al organizar archivos: $e');
    }
  }
}