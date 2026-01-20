import 'package:flutter/material.dart';
import 'package:photo_organizer_pc/features/organizer/data/repositories/organizer_repository.dart';
import 'package:photo_organizer_pc/features/organizer/domain/models/file_item.dart';

class OrganizerViewModel extends ChangeNotifier {
  final OrganizerRepository repository;

  bool? isDeviceConnected;
  bool isLoading = false;
  List<FileItem> tree = [];
  String? errorMessage;
  String? successMessage;

  OrganizerViewModel({required this.repository});

  // Conexión
  Future<void> checkConnection() async {
    _setLoading(true);
    errorMessage = null;

    try {
      final connected = await repository.checkDeviceConnection();
      isDeviceConnected = connected;

      if (!connected) {
        tree.clear();
        errorMessage = 'No hay dispositivo conectado';
      } else {
        successMessage = 'Dispositivo conectado correctamente';
        await _buildRootTree();
      }
    } catch (e) {
      errorMessage = 'Error al verificar conexión: $e';
    } finally {
      _setLoading(false);
    }
  }

  // Cargar árbol
  Future<void> _buildRootTree() async {
    try {
      tree = await repository.buildRootTree();
    } catch (e) {
      errorMessage = 'Error al cargar directorios: $e';
      tree = [];
    }
    notifyListeners();
  }

  // Cargar subdirectorios
  Future<void> loadSubdirectories(FileItem item) async {
    try {
      final children = await repository.loadDirectories(item.path);
      item.children.addAll(children);
      notifyListeners();
    } catch (e) {
      errorMessage = 'Error al cargar subdirectorios: $e';
    }
  }

  // Scrcpy
  Future<void> startScrcpy() async {
    if (isDeviceConnected != true) {
      errorMessage = 'No hay dispositivo conectado';
      notifyListeners();
      return;
    }

    _setLoading(true);
    try {
      await repository.startScrcpy();
      successMessage = 'scrcpy iniciado';
    } catch (e) {
      errorMessage = 'Error al iniciar scrcpy: $e';
    } finally {
      _setLoading(false);
    }
  }

  // Extraer media de hoy
  Future<void> extractTodayMedia() async {
    if (isDeviceConnected != true) {
      errorMessage = 'No hay dispositivo conectado';
      notifyListeners();
      return;
    }

    _setLoading(true);
    try {
      await repository.extractTodayMedia();
      successMessage = 'Archivos de hoy extraídos correctamente';
    } catch (e) {
      errorMessage = 'Error al extraer archivos: $e';
    } finally {
      _setLoading(false);
    }
  }

  // Copiar y organizar media
  Future<void> copyAndOrganizeMedia() async {
    if (isDeviceConnected != true) {
      errorMessage = 'No hay dispositivo conectado';
      notifyListeners();
      return;
    }

    _setLoading(true);
    try {
      await repository.copyAndOrganizeMedia();
      successMessage = 'Archivos copiados y organizados correctamente';
    } catch (e) {
      errorMessage = 'Error al copiar archivos: $e';
    } finally {
      _setLoading(false);
    }
  }

  // Limpiar mensajes
  void clearMessages() {
    errorMessage = null;
    successMessage = null;
    notifyListeners();
  }

  // Helpers
  void _setLoading(bool loading) {
    isLoading = loading;
    notifyListeners();
  }
}