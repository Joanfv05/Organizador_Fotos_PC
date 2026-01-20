import 'package:flutter/material.dart';
import 'package:photo_organizer_pc/features/organizer/domain/models/file_item.dart';

class DirectoryTree extends StatelessWidget {
  final List<FileItem> tree;
  final bool isLoading;
  final bool? isConnected;
  final Function(FileItem) onLoadSubdirectories;

  const DirectoryTree({
    super.key,
    required this.tree,
    required this.isLoading,
    required this.isConnected,
    required this.onLoadSubdirectories,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: Colors.grey.shade300)),
      ),
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : tree.isEmpty
          ? Center(
        child: Text(
          isConnected == true
              ? 'Sin carpetas'
              : 'Dispositivo no conectado',
        ),
      )
          : ListView(
        padding: const EdgeInsets.all(8),
        children: tree.map((item) => _buildItem(item)).toList(),
      ),
    );
  }

  Widget _buildItem(FileItem item) {
    return ExpansionTile(
      leading: const Icon(Icons.folder, color: Colors.blue),
      title: Text(item.name),
      children: item.children.map(_buildItem).toList(),
      onExpansionChanged: (open) {
        if (open && item.children.isEmpty) {
          onLoadSubdirectories(item);
        }
      },
    );
  }
}