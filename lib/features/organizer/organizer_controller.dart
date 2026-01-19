import 'package:flutter/material.dart';
import '../../core/adb/adb_service.dart';
import '../../core/filesystem/file_service.dart';
import '../../core/media/media_item.dart';
import '../../core/media/media_desktop_service.dart';
import '../../core/media/media_service.dart';
import '../../core/utils/date_utils.dart';

class OrganizerController extends ChangeNotifier {
  final MediaService mediaService;
  final FileService fileService;
  final ADBService? adbService; // opcional, solo si quieres conectar móvil

  List<MediaItem> mediaList = [];
  List<MediaItem> selectedItems = [];
  bool loading = false;

  OrganizerController({
    required this.mediaService,
    required this.fileService,
    this.adbService,
  });

  /// Carga todos los archivos desde el servicio de media
  Future<void> loadMedia() async {
    loading = true;
    notifyListeners();

    mediaList = await mediaService.loadMedia();

    loading = false;
    notifyListeners();
  }

  /// Selecciona o deselecciona un archivo
  void toggleSelection(MediaItem item) {
    if (selectedItems.contains(item)) {
      selectedItems.remove(item);
    } else {
      selectedItems.add(item);
    }
    notifyListeners();
  }

  /// Copia los archivos seleccionados a la carpeta destino
  Future<void> copySelected(String destination,
      {bool preserveDate = true}) async {
    if (selectedItems.isEmpty) return;

    final paths = selectedItems.map((e) => e.path).toList();
    await fileService.copyFiles(paths, destination, preserveDate: preserveDate);

    // Limpiamos la selección después de copiar
    selectedItems.clear();
    notifyListeners();
  }

  /// Organiza los archivos en subcarpetas por mes
  Future<void> organizeSelectedByMonth(String folderPath) async {
    await fileService.organizeByMonth(folderPath);
    notifyListeners();
  }

  /// Filtra archivos por un día específico
  void filterByDate(DateTime date) {
    mediaList = mediaList
        .where((item) => DateUtilsHelper.isSameDay(item.date, date))
        .toList();
    notifyListeners();
  }

  /// Filtra archivos por un mes específico
  void filterByMonth(int year, int month) {
    mediaList = mediaList
        .where((item) => DateUtilsHelper.isSameMonth(item.date, DateTime(year, month)))
        .toList();
    notifyListeners();
  }

  /// Verifica si hay móvil conectado (opcional)
  Future<bool> isDeviceConnected() async {
    if (adbService == null) return false;
    return await adbService!.isDeviceConnected();
  }
}
