class FileItem {
  final String name;
  final String path;
  final List<FileItem> children;

  FileItem({
    required this.name,
    required this.path,
    required this.children,
  });
}
