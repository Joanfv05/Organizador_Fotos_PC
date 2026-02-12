import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_organizer_pc/core/adb/adb_service.dart';
import 'package:photo_organizer_pc/features/organizer/domain/models/transfer_progress.dart';
import 'package:path/path.dart' as path;

class WhatsAppViewModel extends ChangeNotifier {
  final ADBService adbService;

  bool? isDeviceConnected;
  String? errorMessage;
  String? successMessage;
  bool isLoading = false;

  TransferProgress? currentProgress;
  String? currentOperation;
  List<String> operationLogs = [];
  String? destinationFolder;

  // Rutas fijas de WhatsApp
  static const String _whatsAppImagesPath =
      '/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/WhatsApp Images';

  static const String _whatsAppVideosPath =
      '/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/WhatsApp Video';

  // Extensiones permitidas
  static const List<String> _imageExtensions = ['.jpg', '.jpeg', '.png', '.heic'];
  static const List<String> _videoExtensions = ['.mp4', '.mov', '.3gp', '.avi'];

  // Meses en español
  static const Map<int, String> _months = {
    1: 'Enero', 2: 'Febrero', 3: 'Marzo', 4: 'Abril',
    5: 'Mayo', 6: 'Junio', 7: 'Julio', 8: 'Agosto',
    9: 'Septiembre', 10: 'Octubre', 11: 'Noviembre', 12: 'Diciembre',
  };

  WhatsAppViewModel({required this.adbService});

  // ============ CONEXIÓN ============
  Future<void> checkConnection() async {
    _setLoading(true);
    errorMessage = null;

    try {
      _addLog('🔌 Verificando conexión con dispositivo...');
      final connected = await adbService.isDeviceConnected();
      isDeviceConnected = connected;

      if (connected) {
        successMessage = '✅ Dispositivo conectado';
        _addLog('✅ Dispositivo conectado');
        await _checkWhatsAppFolders();
      } else {
        errorMessage = '❌ No hay dispositivo conectado';
        _addLog('❌ Dispositivo no conectado');
      }
    } catch (e) {
      errorMessage = '❌ Error de conexión: $e';
      _addLog('❌ Error: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _checkWhatsAppFolders() async {
    try {
      final imagesExist = await adbService.checkDirectoryExists(_whatsAppImagesPath);
      final videosExist = await adbService.checkDirectoryExists(_whatsAppVideosPath);

      if (imagesExist) _addLog('📸 Carpeta WhatsApp Images encontrada');
      if (videosExist) _addLog('🎥 Carpeta WhatsApp Video encontrada');

      if (!imagesExist && !videosExist) {
        _addLog('⚠️ No se encontraron carpetas de WhatsApp');
      }
    } catch (e) {
      _addLog('⚠️ Error verificando carpetas: $e');
    }
  }

  // ============ MÉTODO EJECUTOR ============
  Future<void> _executeOperation({
    required String operationName,
    required Future<void> Function() operation,
    required String successMessage,
    required String errorPrefix,
    String? folderName,
  }) async {
    if (isDeviceConnected != true) {
      _showError('❌ No hay dispositivo conectado');
      return;
    }

    _setLoading(true);
    currentOperation = operationName;
    currentProgress = null;

    if (folderName != null) {
      destinationFolder = await _createLocalBackupDir(folderName);
      _addLog('📁 Carpeta destino: $destinationFolder');
    }

    _addLog('🔄 INICIANDO: $operationName');

    try {
      await operation();
      _showSuccess(successMessage);
    } catch (e) {
      _showError('$errorPrefix: $e');
    } finally {
      _setLoading(false);
      currentOperation = null;
    }
  }

  // ============ COPIAR IMÁGENES ============
  Future<void> copyWhatsAppImagesByYear({required int year}) async {
    final folderName = 'WhatsApp_Imagenes_$year';

    await _executeOperation(
      operationName: 'Copiando imágenes WhatsApp del año $year',
      operation: () => _copyMediaByYear(
        sourcePath: _whatsAppImagesPath,
        year: year,
        extensions: _imageExtensions,
        mediaType: 'imágenes',
      ),
      successMessage: '✅ Imágenes WhatsApp del año $year copiadas',
      errorPrefix: '❌ Error copiando imágenes',
      folderName: folderName,
    );
  }

  Future<void> copyWhatsAppImagesByMonth(int year, int month) async {
    final monthName = _months[month] ?? 'Mes $month';
    final monthStr = month.toString().padLeft(2, '0');
    final folderName = 'WhatsApp_Imagenes_${year}-${monthStr}-$monthName';

    await _executeOperation(
      operationName: 'Copiando imágenes WhatsApp de $monthName $year',
      operation: () => _copyMediaByMonth(
        sourcePath: _whatsAppImagesPath,
        year: year,
        month: month,
        extensions: _imageExtensions,
        mediaType: 'imágenes',
      ),
      successMessage: '✅ Imágenes WhatsApp de $monthName $year copiadas',
      errorPrefix: '❌ Error copiando imágenes',
      folderName: folderName,
    );
  }

  Future<void> copyWhatsAppImagesByDate(DateTime date) async {
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final folderName = 'WhatsApp_Imagenes_$dateStr';

    await _executeOperation(
      operationName: 'Copiando imágenes WhatsApp de $dateStr',
      operation: () => _copyMediaByDate(
        sourcePath: _whatsAppImagesPath,
        date: date,
        extensions: _imageExtensions,
        mediaType: 'imágenes',
      ),
      successMessage: '✅ Imágenes WhatsApp de $dateStr copiadas',
      errorPrefix: '❌ Error copiando imágenes',
      folderName: folderName,
    );
  }

  // ============ COPIAR VÍDEOS ============
  Future<void> copyWhatsAppVideosByYear({required int year}) async {
    final folderName = 'WhatsApp_Videos_$year';

    await _executeOperation(
      operationName: 'Copiando vídeos WhatsApp del año $year',
      operation: () => _copyMediaByYear(
        sourcePath: _whatsAppVideosPath,
        year: year,
        extensions: _videoExtensions,
        mediaType: 'vídeos',
      ),
      successMessage: '✅ Vídeos WhatsApp del año $year copiados',
      errorPrefix: '❌ Error copiando vídeos',
      folderName: folderName,
    );
  }

  Future<void> copyWhatsAppVideosByMonth(int year, int month) async {
    final monthName = _months[month] ?? 'Mes $month';
    final monthStr = month.toString().padLeft(2, '0');
    final folderName = 'WhatsApp_Videos_${year}-${monthStr}-$monthName';

    await _executeOperation(
      operationName: 'Copiando vídeos WhatsApp de $monthName $year',
      operation: () => _copyMediaByMonth(
        sourcePath: _whatsAppVideosPath,
        year: year,
        month: month,
        extensions: _videoExtensions,
        mediaType: 'vídeos',
      ),
      successMessage: '✅ Vídeos WhatsApp de $monthName $year copiados',
      errorPrefix: '❌ Error copiando vídeos',
      folderName: folderName,
    );
  }

  Future<void> copyWhatsAppVideosByDate(DateTime date) async {
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final folderName = 'WhatsApp_Videos_$dateStr';

    await _executeOperation(
      operationName: 'Copiando vídeos WhatsApp de $dateStr',
      operation: () => _copyMediaByDate(
        sourcePath: _whatsAppVideosPath,
        date: date,
        extensions: _videoExtensions,
        mediaType: 'vídeos',
      ),
      successMessage: '✅ Vídeos WhatsApp de $dateStr copiados',
      errorPrefix: '❌ Error copiando vídeos',
      folderName: folderName,
    );
  }

  // ============ MÉTODOS DE COPIA ============
  Future<void> _copyMediaByYear({
    required String sourcePath,
    required int year,
    required List<String> extensions,
    required String mediaType,
  }) async {
    final dirExists = await adbService.checkDirectoryExists(sourcePath);
    if (!dirExists) {
      throw Exception('No se encontró la carpeta de $mediaType');
    }

    final files = await adbService.listFiles(sourcePath);
    if (files.isEmpty) {
      throw Exception('No hay archivos en la carpeta de $mediaType');
    }

    final filteredFiles = _filterFilesByYear(files, year, extensions);
    if (filteredFiles.isEmpty) {
      throw Exception('No se encontraron $mediaType del año $year');
    }

    _addLog('📊 Encontrados ${filteredFiles.length} $mediaType del año $year');
    await _copyFiles(filteredFiles, sourcePath, mediaType);
  }

  Future<void> _copyMediaByMonth({
    required String sourcePath,
    required int year,
    required int month,
    required List<String> extensions,
    required String mediaType,
  }) async {
    final dirExists = await adbService.checkDirectoryExists(sourcePath);
    if (!dirExists) {
      throw Exception('No se encontró la carpeta de $mediaType');
    }

    final files = await adbService.listFiles(sourcePath);
    if (files.isEmpty) {
      throw Exception('No hay archivos en la carpeta de $mediaType');
    }

    final filteredFiles = _filterFilesByMonth(files, year, month, extensions);
    if (filteredFiles.isEmpty) {
      throw Exception('No se encontraron $mediaType de ${_months[month]} $year');
    }

    _addLog('📊 Encontrados ${filteredFiles.length} $mediaType de ${_months[month]} $year');
    await _copyFiles(filteredFiles, sourcePath, mediaType);
  }

  Future<void> _copyMediaByDate({
    required String sourcePath,
    required DateTime date,
    required List<String> extensions,
    required String mediaType,
  }) async {
    final dirExists = await adbService.checkDirectoryExists(sourcePath);
    if (!dirExists) {
      throw Exception('No se encontró la carpeta de $mediaType');
    }

    final files = await adbService.listFiles(sourcePath);
    if (files.isEmpty) {
      throw Exception('No hay archivos en la carpeta de $mediaType');
    }

    final filteredFiles = _filterFilesByDate(files, date, extensions);
    if (filteredFiles.isEmpty) {
      throw Exception('No se encontraron $mediaType para la fecha especificada');
    }

    _addLog('📊 Encontrados ${filteredFiles.length} $mediaType para la fecha');
    await _copyFiles(filteredFiles, sourcePath, mediaType);
  }

  // ============ FILTROS ============
  List<String> _filterFilesByYear(
      List<String> files,
      int year,
      List<String> extensions,
      ) {
    final yearStr = year.toString();
    return files.where((file) {
      if (!_hasValidExtension(file, extensions)) return false;

      // Patrón para WhatsApp: IMG-20250210-WA0001.jpg o VID-20250210-WA0002.mp4
      final match = RegExp(r'(?:IMG|VID)-(\d{4})(\d{2})(\d{2})').firstMatch(file);
      if (match == null) return false;

      final fileYear = match.group(1);
      return fileYear == yearStr;
    }).toList();
  }

  List<String> _filterFilesByMonth(
      List<String> files,
      int year,
      int month,
      List<String> extensions,
      ) {
    final yearStr = year.toString();
    final monthStr = month.toString().padLeft(2, '0');

    return files.where((file) {
      if (!_hasValidExtension(file, extensions)) return false;

      final match = RegExp(r'(?:IMG|VID)-(\d{4})(\d{2})(\d{2})').firstMatch(file);
      if (match == null) return false;

      final fileYear = match.group(1);
      final fileMonth = match.group(2);
      return fileYear == yearStr && fileMonth == monthStr;
    }).toList();
  }

  List<String> _filterFilesByDate(
      List<String> files,
      DateTime date,
      List<String> extensions,
      ) {
    final dateStr = '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';

    return files.where((file) {
      if (!_hasValidExtension(file, extensions)) return false;
      return file.contains('-$dateStr-');
    }).toList();
  }

  bool _hasValidExtension(String filename, List<String> extensions) {
    final ext = path.extension(filename).toLowerCase();
    return extensions.contains(ext);
  }

  // ============ COPIA DE ARCHIVOS ============
  Future<void> _copyFiles(
      List<String> files,
      String sourceDir,
      String mediaType,
      ) async {
    if (destinationFolder == null) return;

    for (int i = 0; i < files.length; i++) {
      final file = files[i];
      final remotePath = '$sourceDir/$file';
      final localPath = path.join(destinationFolder!, file);

      currentProgress = TransferProgress(
        current: i + 1,
        total: files.length,
        currentFile: file,
        type: TransferType.pull,
        sourcePath: remotePath,
        destinationPath: localPath,
      );
      notifyListeners();

      _addLog('📥 ${i + 1}/${files.length}: $file');

      try {
        await adbService.pullFile(remotePath, localPath);
      } catch (e) {
        _addLog('⚠️ Error con $file: $e');
      }

      await Future.delayed(const Duration(milliseconds: 50));
    }

    _addLog('✅ Copia completada: ${files.length} $mediaType');
    currentProgress = null;
    notifyListeners();
  }

  // ============ UTILIDADES ============
  Future<String> _createLocalBackupDir(String folderName) async {
    try {
      final currentDir = Directory.current;
      final projectRoot = Directory(path.join(currentDir.path, '..', '..'));
      final targetDir = Directory(path.join(projectRoot.absolute.path, folderName));
      await targetDir.create(recursive: true);
      return targetDir.path;
    } catch (e) {
      final homeDir = Platform.environment['HOME'] ?? '';
      final fallbackDir = Directory(path.join(homeDir, 'WhatsApp', folderName));
      await fallbackDir.create(recursive: true);
      return fallbackDir.path;
    }
  }

  // ============ LOGS ============
  void _addLog(String message) {
    final now = DateTime.now();
    final timestamp = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    operationLogs.add('[$timestamp] $message');
    if (operationLogs.length > 100) operationLogs.removeAt(0);
    notifyListeners();
  }

  void _showSuccess(String message) {
    successMessage = message;
    _addLog('✅ $message');
    _clearMessageAfterDelay(message, true);
    notifyListeners();
  }

  void _showError(String message) {
    errorMessage = message;
    _addLog('❌ $message');
    _clearMessageAfterDelay(message, false);
    notifyListeners();
  }

  void _clearMessageAfterDelay(String message, bool isSuccess) {
    Future.delayed(Duration(seconds: isSuccess ? 3 : 5), () {
      if (isSuccess && successMessage == message) successMessage = null;
      if (!isSuccess && errorMessage == message) errorMessage = null;
      notifyListeners();
    });
  }

  void _setLoading(bool loading) {
    isLoading = loading;
    notifyListeners();
  }

  void clearMessages() {
    errorMessage = null;
    successMessage = null;
    notifyListeners();
  }

  void clearLogs() {
    operationLogs.clear();
    _addLog('🗑️ Registro limpiado');
    notifyListeners();
  }
}