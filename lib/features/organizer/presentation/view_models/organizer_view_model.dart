import 'dart:io';

import 'package:flutter/material.dart';
import 'package:photo_organizer_pc/features/organizer/data/repositories/organizer_repository.dart';
import 'package:photo_organizer_pc/features/organizer/domain/models/file_item.dart';
import 'package:photo_organizer_pc/features/organizer/domain/models/transfer_progress.dart';

class OrganizerViewModel extends ChangeNotifier {
  final OrganizerRepository repository;

  bool? isDeviceConnected;
  List<FileItem> tree = [];
  String? errorMessage;
  String? successMessage;
  bool isTreeLoading = false;
  bool isActionLoading = false;

  TransferProgress? currentProgress;
  String? currentOperation;
  List<String> operationLogs = [];
  String? destinationFolder;
  String? selectedFolderName;

  // NUEVO: Para guardar la última ruta de destino
  String? _lastDestinationPath;
  String? get lastDestinationPath => _lastDestinationPath;

  // NUEVO: Para la ruta actual de destino (durante operación)
  String? _currentDestinationPath;
  String? get currentDestinationPath => _currentDestinationPath;

  OrganizerViewModel({required this.repository});

  // ============ CONEXIÓN ============
  Future<void> checkConnection() async {
    _setTreeLoading(true);
    errorMessage = null;
    _clearProgress();

    try {
      _addLog('🔌 Verificando conexión con dispositivo...');
      final connected = await repository.checkDeviceConnection();
      isDeviceConnected = connected;

      if (!connected) {
        tree.clear();
        errorMessage = '❌ No hay dispositivo conectado';
        _addLog('❌ Dispositivo no encontrado');
      } else {
        successMessage = '✅ Dispositivo conectado correctamente';
        _addLog('✅ Dispositivo conectado exitosamente');
        await _buildRootTree();
      }
    } catch (e) {
      errorMessage = '❌ Error al verificar conexión: $e';
      _addLog('❌ Error de conexión: $e');
    } finally {
      _setTreeLoading(false);
    }
  }

  // ============ ÁRBOL DE DIRECTORIOS ============
  Future<void> _buildRootTree() async {
    try {
      _addLog('📁 Cargando estructura de directorios...');
      tree = await repository.buildRootTree();
      _addLog('✅ Directorios cargados: ${tree.length} raíces encontradas');
    } catch (e) {
      errorMessage = '❌ Error al cargar directorios: $e';
      tree = [];
      _addLog('❌ Error cargando directorios: $e');
    }
    notifyListeners();
  }

  Future<void> loadSubdirectories(FileItem item) async {
    _setTreeLoading(true);
    try {
      _addLog('📂 Explorando: ${item.path}');
      final children = await repository.loadDirectories(item.path);
      item.children.addAll(children);
      _addLog('✅ Encontradas ${children.length} subcarpetas');
    } catch (e) {
      errorMessage = '❌ Error al cargar subdirectorios: $e';
      _addLog('❌ Error explorando carpeta: $e');
    } finally {
      _setTreeLoading(false);
    }
  }

  // ============ MÉTODO REUTILIZABLE PARA OPERACIONES ============
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

    _setActionLoading(true);
    _clearCurrentOperation();
    currentOperation = operationName;
    selectedFolderName = folderName;

    if (folderName != null) {
      try {
        final dirPath = await repository.getBackupDirectoryPath(folderName);
        destinationFolder = dirPath;
        _currentDestinationPath = dirPath; // NUEVO: Guardar ruta actual
        _addLog('📁 Carpeta destino: ${destinationFolder}');
      } catch (e) {
        _addLog('⚠️ No se pudo crear carpeta: $e');
        destinationFolder = null;
        _currentDestinationPath = null;
      }
    }

    _addLog('🔄 INICIANDO: $operationName');
    if (destinationFolder != null) {
      _addLog('📁 Carpeta destino: ${destinationFolder}');
    }

    try {
      await operation();

      // NUEVO: Guardar la ruta como última ruta usada
      if (destinationFolder != null) {
        _lastDestinationPath = destinationFolder;
        _addLog('💾 Ruta guardada para futuras referencias');
      }

      _showSuccess(successMessage);
    } catch (e) {
      _showError('$errorPrefix: $e');
    } finally {
      _setActionLoading(false);
      if (!isActionLoading) {
        _clearCurrentOperation();
      }
    }
  }

  // ============ SCRCPY ============
  Future<void> startScrcpy() async {
    await _executeOperation(
      operationName: 'Iniciando control remoto',
      operation: () async {
        await repository.startScrcpy();
        _addLog('💡 Puedes ver y controlar tu dispositivo desde la ventana que se abrió');
      },
      successMessage: '✅ scrcpy iniciado correctamente',
      errorPrefix: '❌ Error al iniciar scrcpy',
    );
  }

  // ============ EXTRACCIÓN DE FOTOS DE HOY ============
  Future<void> extractTodayMedia() async {
    final today = DateTime.now();
    final folderName = 'Fotos_${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    await _executeOperation(
      operationName: 'Extrayendo fotos de hoy',
      operation: () async {
        await repository.extractTodayMedia(
          onProgress: (progress) => _handleProgress(progress, 'hoy'),
        );
      },
      successMessage: '✅ Archivos de hoy extraídos correctamente',
      errorPrefix: '❌ Error al extraer archivos',
      folderName: folderName,
    );
  }

  // ============ COPIAR Y ORGANIZAR POR AÑO ============
  Future<void> copyAndOrganizeMedia({required int year}) async {
    final folderName = 'Fotos_$year';

    await _executeOperation(
      operationName: 'Copiando y organizando media del año $year',
      operation: () async {
        await repository.copyAndOrganizeMedia(
          year: year,
          onProgress: (progress) => _handleProgress(progress, 'año $year'),
        );
      },
      successMessage: '✅ Archivos del año $year copiados y organizados correctamente',
      errorPrefix: '❌ Error al copiar archivos del año $year',
      folderName: folderName,
    );
  }

  // ============ COPIAR DE FECHA ESPECÍFICA ============
  Future<void> extractSpecificDateMedia(DateTime? selectedDate) async {
    if (selectedDate == null) {
      _showError('❌ Por favor selecciona una fecha');
      return;
    }

    final dateStr = '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}';
    final folderName = 'Fotos_${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';

    await _executeOperation(
      operationName: 'Copiando fotos de fecha específica',
      operation: () async {
        final matchingFiles = await repository.findFilesByDate(selectedDate);
        _addLog('📊 Encontrados ${matchingFiles.length} archivos para la fecha');

        if (matchingFiles.isEmpty) {
          _showSuccess('ℹ️ No se encontraron archivos para la fecha $dateStr');
          return;
        }

        await repository.extractMediaFromSpecificDate(
          selectedDate,
          onProgress: (progress) => _handleProgress(progress, 'fecha $dateStr'),
        );
      },
      successMessage: '✅ Archivos de $dateStr copiados correctamente',
      errorPrefix: '❌ Error al copiar archivos',
      folderName: folderName,
    );
  }

  // ============ COPIAR DE MES ESPECÍFICO ============
  Future<void> copyMediaByMonth(int year, int month) async {
    final monthName = _getMonthName(month);
    final monthStr = month.toString().padLeft(2, '0');
    final folderName = 'Fotos_${year}-${monthStr}-$monthName';

    await _executeOperation(
      operationName: 'Copiando fotos y vídeos del mes específico',
      operation: () async {
        await repository.copyMediaByMonth(
          year: year,
          month: month,
          onProgress: (progress) => _handleProgress(progress, 'mes $monthName $year'),
        );
      },
      successMessage: '✅ Fotos y vídeos de $monthName $year copiados correctamente',
      errorPrefix: '❌ Error al copiar archivos del mes',
      folderName: folderName,
    );
  }

  // ============ COPIAR DESDE ALMACENAMIENTO INTERNO ============
  Future<void> copyFromInternalStorage({required int year}) async {
    final folderName = 'Fotos_Internas_$year';

    await _executeOperation(
      operationName: 'Copiando desde almacenamiento interno - Año $year',
      operation: () async {
        await repository.copyFromInternalStorage(
          year: year,
          onProgress: (progress) => _handleProgress(progress, 'interno año $year'),
        );
      },
      successMessage: '✅ Archivos del año $year (interno) copiados correctamente',
      errorPrefix: '❌ Error al copiar archivos del interno',
      folderName: folderName,
    );
  }

  Future<void> copyFromInternalStorageByMonth(int year, int month) async {
    final monthName = _getMonthName(month);
    final monthStr = month.toString().padLeft(2, '0');
    final folderName = 'Fotos_Internas_${year}-${monthStr}-$monthName';

    await _executeOperation(
      operationName: 'Copiando desde almacenamiento interno - Mes específico',
      operation: () async {
        await repository.copyFromInternalStorageByMonth(
          year: year,
          month: month,
          onProgress: (progress) => _handleProgress(progress, 'interno mes $monthName $year'),
        );
      },
      successMessage: '✅ Fotos y vídeos de $monthName $year (interno) copiados',
      errorPrefix: '❌ Error al copiar archivos del interno (mes)',
      folderName: folderName,
    );
  }

  // ============ EXTRACCIÓN DE HOY DESDE INTERNO ============
  Future<void> extractTodayMediaFromInternal() async {
    final today = DateTime.now();
    final folderName = 'Fotos_Internas_${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    await _executeOperation(
      operationName: 'Extrayendo fotos de hoy desde interno',
      operation: () async {
        await repository.extractTodayMediaFromInternal(
          onProgress: (progress) => _handleProgress(progress, 'hoy (interno)'),
        );
      },
      successMessage: '✅ Archivos de hoy (interno) extraídos correctamente',
      errorPrefix: '❌ Error al extraer archivos desde interno',
      folderName: folderName,
    );
  }

// ============ COPIAR DE FECHA ESPECÍFICA DESDE INTERNO ============
  Future<void> extractSpecificDateFromInternal(DateTime? selectedDate) async {
    if (selectedDate == null) {
      _showError('❌ Por favor selecciona una fecha');
      return;
    }

    final dateStr = '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}';
    final folderName = 'Fotos_Internas_${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';

    await _executeOperation(
      operationName: 'Copiando fotos de fecha específica desde interno',
      operation: () async {
        final matchingFiles = await repository.findFilesByDateInternal(selectedDate);
        _addLog('📊 Encontrados ${matchingFiles.length} archivos para la fecha en interno');

        if (matchingFiles.isEmpty) {
          _showSuccess('ℹ️ No se encontraron archivos para la fecha $dateStr en interno');
          return;
        }

        await repository.extractSpecificDateFromInternal(
          selectedDate,
          onProgress: (progress) => _handleProgress(progress, 'fecha $dateStr (interno)'),
        );
      },
      successMessage: '✅ Archivos de $dateStr (interno) copiados correctamente',
      errorPrefix: '❌ Error al copiar archivos desde interno',
      folderName: folderName,
    );
  }

  // ============ CAPTURAS DE PANTALLA ============
  Future<void> copyScreenshotsByYear({required int year}) async {
    final folderName = 'Capturas_$year';

    await _executeOperation(
      operationName: 'Copiando capturas de pantalla del año $year',
      operation: () async {
        await repository.copyScreenshotsByYear(
          year: year,
          onProgress: (progress) => _handleProgress(progress, 'capturas año $year'),
        );
      },
      successMessage: '✅ Capturas del año $year copiadas y organizadas',
      errorPrefix: '❌ Error al copiar capturas del año $year',
      folderName: folderName,
    );
  }

  Future<void> copyScreenshotsByMonth({required int year, required int month}) async {
    final monthName = _getMonthName(month);
    final monthStr = month.toString().padLeft(2, '0');
    final folderName = 'Capturas_${year}-${monthStr}-$monthName';

    await _executeOperation(
      operationName: 'Copiando capturas de $monthName $year',
      operation: () async {
        await repository.copyScreenshotsByMonth(
          year: year,
          month: month,
          onProgress: (progress) => _handleProgress(progress, 'capturas $monthName $year'),
        );
      },
      successMessage: '✅ Capturas de $monthName $year copiadas',
      errorPrefix: '❌ Error al copiar capturas del mes',
      folderName: folderName,
    );
  }

  Future<void> copyScreenshotsByDate(DateTime? selectedDate) async {
    if (selectedDate == null) {
      _showError('❌ Por favor selecciona una fecha');
      return;
    }

    final dateStr = '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}';
    final folderName = 'Capturas_${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';

    await _executeOperation(
      operationName: 'Copiando capturas de $dateStr',
      operation: () async {
        await repository.copyScreenshotsByDate(
          date: selectedDate,
          onProgress: (progress) => _handleProgress(progress, 'capturas $dateStr'),
        );
      },
      successMessage: '✅ Capturas de $dateStr copiadas',
      errorPrefix: '❌ Error al copiar capturas de fecha específica',
      folderName: folderName,
    );
  }

  // ============ MANEJO DE PROGRESO REUTILIZABLE ============
  void _handleProgress(TransferProgress progress, String context) {
    currentProgress = progress;

    switch (progress.type) {
      case TransferType.scanning:
        _addLog('🔍 ${progress.currentFile}');
        break;
      case TransferType.pull:
        _addLog('📥 Descargando: ${progress.currentFile}');
        if (progress.sourcePath != null && progress.destinationPath != null) {
          _addLog('   ↪️ De: ${progress.sourcePath}');
          _addLog('   ↩️ A: ${progress.destinationPath}');
        }
        break;
      case TransferType.organizing:
        _addLog('📂 Organizando: ${progress.currentFile}');
        if (progress.destinationPath != null) {
          _addLog('   📍 Mover a: ${progress.destinationPath}');
        }
        break;
      default:
        _addLog('⚙️ ${progress.currentFile}');
    }

    if (progress.current % 10 == 0 || progress.current == 1) {
      _addLog('📊 Progreso: ${progress.current}/${progress.total} (${progress.percentage.toStringAsFixed(1)}%)');
    }

    notifyListeners();
  }

  // ============ HELPERS DE MENSAJES ============
  void _showSuccess(String message) {
    successMessage = message;
    _addLog('🎉 $message');
    _clearMessageAfterDelay(successMessage, true);
    notifyListeners();
  }

  void _showError(String message) {
    errorMessage = message;
    _addLog('❌ $message');
    _clearMessageAfterDelay(errorMessage, false);
    notifyListeners();
  }

  void _clearMessageAfterDelay(String? message, bool isSuccess) {
    Future.delayed(Duration(seconds: isSuccess ? 3 : 5), () {
      if (isSuccess && successMessage == message) {
        successMessage = null;
      } else if (!isSuccess && errorMessage == message) {
        errorMessage = null;
      }
      notifyListeners();
    });
  }

  String _getMonthName(int month) {
    const monthNames = {
      1: 'Enero', 2: 'Febrero', 3: 'Marzo', 4: 'Abril',
      5: 'Mayo', 6: 'Junio', 7: 'Julio', 8: 'Agosto',
      9: 'Septiembre', 10: 'Octubre', 11: 'Noviembre', 12: 'Diciembre'
    };
    return monthNames[month] ?? 'Mes $month';
  }

  // ============ MÉTODOS DE PROGRESO ============
  void updateProgress(TransferProgress progress) {
    currentProgress = progress;
    notifyListeners();
  }

  void updateCurrentOperation(String operation) {
    currentOperation = operation;
    _addLog('🔄 Cambiando a: $operation');
    notifyListeners();
  }

  void _addLog(String message) {
    final now = DateTime.now();
    final timestamp = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    String formattedMessage = message;
    if (!message.startsWith(RegExp(r'[🔌📁📂📷📅📁📊🔍📥📂⚙️🎉❌✅💡📍↪️↩️🔄🖥️📝]'))) {
      if (message.toLowerCase().contains('error') || message.contains('❌')) {
        formattedMessage = '❌ $message';
      } else if (message.toLowerCase().contains('éxito') ||
          message.toLowerCase().contains('completado') ||
          message.contains('✅')) {
        formattedMessage = '✅ $message';
      } else if (message.toLowerCase().contains('buscando') ||
          message.toLowerCase().contains('escaneando') ||
          message.contains('🔍')) {
        formattedMessage = '🔍 $message';
      } else if (message.toLowerCase().contains('descargando') ||
          message.toLowerCase().contains('copiando') ||
          message.contains('📥')) {
        formattedMessage = '📥 $message';
      }
    }

    operationLogs.add('[$timestamp] $formattedMessage');

    if (operationLogs.length > 100) {
      operationLogs.removeAt(0);
    }

    notifyListeners();
  }

  void _clearProgress() {
    currentProgress = null;
    destinationFolder = null;
    selectedFolderName = null;
    notifyListeners();
  }

  void _clearCurrentOperation() {
    currentOperation = null;
    _currentDestinationPath = null;
    currentProgress = null;
    notifyListeners();
  }

  void clearLogs() {
    operationLogs.clear();
    _addLog('🗑️ Registro limpiado por el usuario');
    notifyListeners();
  }

  void clearMessages() {
    errorMessage = null;
    successMessage = null;
    notifyListeners();
  }

  // NUEVO: Método para limpiar la ruta guardada
  void clearLastDestinationPath() {
    _lastDestinationPath = null;
    _addLog('🗑️ Ruta guardada eliminada');
    notifyListeners();
  }

  // ============ HELPERS DE LOADING ============
  void _setTreeLoading(bool loading) {
    isTreeLoading = loading;
    notifyListeners();
  }

  void _setActionLoading(bool loading) {
    isActionLoading = loading;
    if (!loading) {
      // Limpiar la operación actual cuando se completa
      _clearCurrentOperation();
    }
    notifyListeners();
  }

  // ============ PROPIEDADES CALCULADAS ============
  bool get isAnyLoading => isTreeLoading || isActionLoading;

  bool get hasActiveOperation => isActionLoading && currentOperation != null;

  String get statusSummary {
    if (isDeviceConnected == null) return 'Estado: No verificado';
    if (!isDeviceConnected!) return 'Estado: Desconectado 🔴';
    if (isAnyLoading) return 'Estado: Procesando 🟡';
    return 'Estado: Conectado y listo 🟢';
  }

  String? get lastLog {
    if (operationLogs.isEmpty) return null;
    return operationLogs.last;
  }

  int get totalLogs => operationLogs.length;

  // ============ MÉTODOS PÚBLICOS ADICIONALES ============
  void addUserLog(String message) {
    _addLog('👤 $message');
  }

  void showSuccess(String message) {
    successMessage = message;
    _addLog('✅ $message');
    notifyListeners();

    Future.delayed(const Duration(seconds: 3), () {
      if (successMessage == message) {
        successMessage = null;
        notifyListeners();
      }
    });
  }

  void showError(String message) {
    errorMessage = message;
    _addLog('❌ $message');
    notifyListeners();

    Future.delayed(const Duration(seconds: 5), () {
      if (errorMessage == message) {
        errorMessage = null;
        notifyListeners();
      }
    });
  }
}