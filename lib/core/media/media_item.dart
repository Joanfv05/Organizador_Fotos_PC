class MediaItem {
  final String path; // ruta del archivo
  final DateTime date; // fecha de creación/modificación
  final String name; // nombre del archivo (opcional)
  final int size; // tamaño en bytes (opcional)

  MediaItem({
    required this.path,
    required this.date,
    required this.name,
    required this.size,
  });
}
