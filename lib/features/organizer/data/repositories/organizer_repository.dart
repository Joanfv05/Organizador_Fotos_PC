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

    // Dar permisos en Linux
    if (!Platform.isWindows) {
      await Process.run('chmod', ['+x', scrcpyPath]);
    }

    if (Platform.isWindows) {
      await Process.start(scrcpyPath, args, mode: ProcessStartMode.detachedWithStdio);
    } else {
      // Linux necesita ejecutar desde su directorio
      final scrcpyDir = Directory(path.dirname(scrcpyPath));
      await Process.run(scrcpyPath, args, workingDirectory: scrcpyDir.path);
    }
  }

  // ============ EXTRACCIÓN DE MEDIA ============
  Future<void> extractTodayMedia({
    Function(TransferProgress)? onProgress,
  }) async {
    await extractorService.extractTodayMedia(onProgress: onProgress);
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
    final localBackupDir = await _createLocalBackupDir('Fotos del Mes - $year-$monthStr');

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
    await extractorService.extractMediaFromDate(
      date,
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
      // OPCIÓN A: Raíz del proyecto (2 niveles arriba desde /lib/)
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

      // Verificar creación
      if (await targetDir.exists()) {
        print('✅ Carpeta creada exitosamente');

        // Listar contenido para debug
        final parent = targetDir.parent;
        print('📂 Contenido de ${parent.path}:');
        try {
          final entries = await parent.list().toList();
          for (var entry in entries) {
            print('   - ${path.basename(entry.path)}');
          }
        } catch (e) {
          print('   (No se pudo listar contenido)');
        }
      } else {
        print('⚠️ Advertencia: No se pudo verificar la creación');
      }

      return targetDir;

    } catch (e) {
      print('🔴 Error creando carpeta: $e');

      // Fallback definitivo: HOME del usuario
      final homeDir = Platform.environment['HOME']!;
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
    final ext = filename.toLowerCase();
    return _mediaExtensions.any((mediaExt) => ext.endsWith(mediaExt));
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

      if (onProgress != null) {
        onProgress(TransferProgress(
          current: i + 1,
          total: files.length,
          currentFile: file,
          type: TransferType.pull,
        ));
      }

      await adbService.pullFile(remotePath, localPath);
      await Future.delayed(const Duration(milliseconds: 10));
    }
  }

  Future<void> _organizeByMonth(String sourceDir,
      {Function(TransferProgress)? onProgress}) async {
    final sourceDirectory = Directory(sourceDir);
    final files = await sourceDirectory
        .list()
        .where((e) => e is File)
        .cast<File>()
        .toList();

    for (int i = 0; i < files.length; i++) {
      final file = files[i];
      final fileName = file.path.split('/').last;
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
      }

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
}