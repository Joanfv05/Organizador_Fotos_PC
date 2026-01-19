import 'dart:io';
import 'media_service.dart';
import 'media_item.dart';

class MediaDesktopService implements MediaService {
  final String folderPath;

  MediaDesktopService({this.folderPath = '/home/joan/Fotos'});

  @override
  Future<List<MediaItem>> loadMedia() async {
    await Future.delayed(const Duration(seconds: 1));

    final dir = Directory(folderPath);
    if (!dir.existsSync()) return [];

    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) =>
    f.path.toLowerCase().endsWith('.jpg') ||
        f.path.toLowerCase().endsWith('.png') ||
        f.path.toLowerCase().endsWith('.mp4'))
        .toList();

    return files.map((file) {
      final stat = file.statSync();
      return MediaItem(
        path: file.path,
        name: file.uri.pathSegments.last,
        date: stat.modified,
        size: stat.size,
      );
    }).toList();
  }
}
