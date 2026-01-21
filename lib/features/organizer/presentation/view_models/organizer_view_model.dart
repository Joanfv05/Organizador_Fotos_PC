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
  String? destinationFolder; // NUEVA: Carpeta destino actual

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

  // ============ SCRCPY ============
  Future<void> startScrcpy() async {
    if (isDeviceConnected != true) {
      errorMessage = '❌ No hay dispositivo conectado';
      notifyListeners();
      return;
    }

    _setActionLoading(true);
    _clearProgress();
    currentOperation = 'Iniciando control remoto';
    _addLog('🖥️ Iniciando scrcpy (control remoto)...');

    try {
      await repository.startScrcpy();
      successMessage = '✅ scrcpy iniciado correctamente';
      _addLog('✅ Control remoto iniciado');
      _addLog('💡 Puedes ver y controlar tu dispositivo desde la ventana que se abrió');
    } catch (e) {
      errorMessage = '❌ Error al iniciar scrcpy: $e';
      _addLog('❌ Error iniciando control remoto: $e');
    } finally {
      _setActionLoading(false);
      _clearProgress();
    }
  }

  // ============ EXTRACCIÓN DE FOTOS DE HOY ============
  Future<void> extractTodayMedia() async {
    if (isDeviceConnected != true) {
      errorMessage = '❌ No hay dispositivo conectado';
      notifyListeners();
      return;
    }

    _setActionLoading(true);
    _clearProgress();
    currentOperation = 'Extrayendo fotos de hoy';

    // Establecer carpeta destino con fecha actual
    final today = DateTime.now();
    destinationFolder = 'Fotos_${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    _addLog('📷 INICIANDO EXTRACCIÓN DE FOTOS DE HOY');
    _addLog('📅 Fecha objetivo: ${today.day}/${today.month}/${today.year}');
    _addLog('📁 Carpeta destino: ./$destinationFolder');
    _addLog('🔍 Buscando fotos en la tarjeta SD...');

    try {
      await repository.extractTodayMedia(
        onProgress: (progress) {
          currentProgress = progress;

          // Logs específicos según el tipo de operación
          if (progress.type == TransferType.scanning) {
            _addLog('🔍 Escaneando: ${progress.currentFile}');
          } else {
            _addLog('📥 Descargando: ${progress.currentFile} (${progress.current}/${progress.total})');
          }

          notifyListeners();
        },
      );

      successMessage = '✅ Archivos de hoy extraídos correctamente';
      _addLog('🎉 EXTRACCIÓN COMPLETADA EXITOSAMENTE');
      _addLog('📂 Archivos guardados en: ./$destinationFolder');
      _addLog('📍 Ruta completa: ${Directory(destinationFolder!).absolute.path}');

    } catch (e) {
      errorMessage = '❌ Error al extraer archivos: $e';
      _addLog('❌ ERROR DURANTE EXTRACCIÓN: $e');
    } finally {
      _setActionLoading(false);
      _clearProgress();
    }
  }

  // ============ COPIAR Y ORGANIZAR MEDIA ============
  Future<void> copyAndOrganizeMedia() async {
    if (isDeviceConnected != true) {
      errorMessage = '❌ No hay dispositivo conectado';
      notifyListeners();
      return;
    }

    _setActionLoading(true);
    _clearProgress();
    currentOperation = 'Copiando y organizando media';
    destinationFolder = 'LocalBackup'; // Carpeta por defecto

    _addLog('🔄 INICIANDO COPIA Y ORGANIZACIÓN');
    _addLog('📁 Carpeta destino principal: ./$destinationFolder');
    _addLog('📊 Los archivos se organizarán por mes dentro de esta carpeta');
    _addLog('🔍 Detectando carpeta de fotos en la SD...');

    try {
      await repository.copyAndOrganizeMedia(
        onProgress: (progress) {
          currentProgress = progress;

          // Logs detallados según el tipo de operación
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

          // Mostrar porcentaje cada 10 archivos o cuando cambia mucho
          if (progress.current % 10 == 0 || progress.current == 1) {
            _addLog('📊 Progreso: ${progress.current}/${progress.total} (${progress.percentage.toStringAsFixed(1)}%)');
          }

          notifyListeners();
        },
      );

      successMessage = '✅ Archivos copiados y organizados correctamente';
      _addLog('🎉 PROCESO COMPLETADO EXITOSAMENTE');
      _addLog('📂 Archivos organizados en: ./$destinationFolder');
      _addLog('📅 Organización: Por mes (Ej: 2024-01, 2024-02, etc.)');
      _addLog('📝 Archivos sin fecha en carpeta: ./$destinationFolder/SinFecha');
      _addLog('📍 Ruta completa: ${Directory(destinationFolder!).absolute.path}');

    } catch (e) {
      errorMessage = '❌ Error al copiar archivos: $e';
      _addLog('❌ ERROR DURANTE COPIA: $e');
      _addLog('💡 Sugerencia: Verifica que la tarjeta SD esté insertada y tenga fotos');
    } finally {
      _setActionLoading(false);
      _clearProgress();
    }
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

    // Añadir emojis automáticamente según el contenido
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

    // Mantener solo los últimos 100 logs (más para mejor visibilidad)
    if (operationLogs.length > 100) {
      operationLogs.removeAt(0);
    }

    notifyListeners();
  }

  void _clearProgress() {
    currentProgress = null;
    currentOperation = null;
    destinationFolder = null;
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

  // ============ HELPERS DE LOADING ============
  void _setTreeLoading(bool loading) {
    isTreeLoading = loading;
    notifyListeners();
  }

  void _setActionLoading(bool loading) {
    isActionLoading = loading;
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

    // Limpiar mensaje después de 3 segundos
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

    // Limpiar mensaje después de 5 segundos
    Future.delayed(const Duration(seconds: 5), () {
      if (errorMessage == message) {
        errorMessage = null;
        notifyListeners();
      }
    });
  }
}