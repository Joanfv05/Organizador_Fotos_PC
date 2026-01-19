import 'dart:io';
import 'package:path/path.dart' as p;

class FileService {
  /// Copia una lista de archivos desde su ruta original a la carpeta destino
  /// Mantiene la fecha de modificación original si preserveDate = true
  Future<void> copyFiles(List<String> files, String destination,
      {bool preserveDate = true}) async {
    final destDir = Directory(destination);
    if (!destDir.existsSync()) {
      destDir.createSync(recursive: true);
    }

    for (var filePath in files) {
      final file = File(filePath);
      if (!file.existsSync()) continue;

      final newPath = p.join(destination, p.basename(filePath));
      await file.copy(newPath);

      if (preserveDate) {
        final stat = await file.stat();
        await File(newPath).setLastModified(stat.modified);
      }
    }
  }

  /// Organiza archivos en subcarpetas por mes (YYYY-MM)
  Future<void> organizeByMonth(String folderPath) async {
    final folder = Directory(folderPath);
    if (!folder.existsSync()) return;

    final files = folder.listSync().whereType<File>();
    for (var file in files) {
      final date = file.statSync().modified;
      final monthFolderName = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      final newFolder = Directory(p.join(folderPath, monthFolderName));
      if (!newFolder.existsSync()) newFolder.createSync();

      final newPath = p.join(newFolder.path, p.basename(file.path));
      await file.rename(newPath); // mueve archivo a subcarpeta
    }
  }

  /// Filtra archivos por fecha (día específico)
  List<String> filterByDate(List<String> files, DateTime date) {
    return files.where((path) {
      final file = File(path);
      if (!file.existsSync()) return false;
      final modified = file.statSync().modified;
      return modified.year == date.year &&
          modified.month == date.month &&
          modified.day == date.day;
    }).toList();
  }

  /// Filtra archivos por mes (YYYY-MM)
  List<String> filterByMonth(List<String> files, int year, int month) {
    return files.where((path) {
      final file = File(path);
      if (!file.existsSync()) return false;
      final modified = file.statSync().modified;
      return modified.year == year && modified.month == month;
    }).toList();
  }
}
