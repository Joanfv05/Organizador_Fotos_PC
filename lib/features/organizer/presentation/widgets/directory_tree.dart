import 'package:flutter/material.dart';
import 'package:photo_organizer_pc/features/organizer/domain/models/file_item.dart';

class DirectoryTree extends StatefulWidget {
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
  State<DirectoryTree> createState() => _DirectoryTreeState();
}

class _DirectoryTreeState extends State<DirectoryTree> {
  // Mapa para rastrear el estado de expansión de cada carpeta
  final Map<String, bool> _expansionStates = {};

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: Colors.grey.shade300)),
      ),
      child: widget.isLoading
          ? const Center(child: CircularProgressIndicator())
          : widget.tree.isEmpty
          ? Center(
        child: Text(
          widget.isConnected == true
              ? 'Sin carpetas'
              : 'Dispositivo no conectado',
        ),
      )
          : ListView(
        padding: const EdgeInsets.all(8),
        children: widget.tree.map((item) => _buildItem(item)).toList(),
      ),
    );
  }

  Widget _buildItem(FileItem item) {
    // Si no tenemos un estado para este item, lo inicializamos como colapsado
    final isExpanded = _expansionStates[item.path] ?? false;

    return ExpansionTile(
      key: ValueKey(item.path), // Key única para cada item
      leading: Icon(
        isExpanded ? Icons.folder_open : Icons.folder,
        color: Colors.blue,
      ),
      title: Text(
        item.name,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: isExpanded ? Colors.blue[800] : Colors.grey[800],
        ),
      ),
      initiallyExpanded: isExpanded,
      // Si no hay children, simplemente no mostrar nada (lista vacía)
      children: item.children.map(_buildItem).toList(),
      onExpansionChanged: (open) {
        setState(() {
          // Guardar el estado de expansión
          _expansionStates[item.path] = open;

          // Solo cargar subdirectorios si se está expandiendo y aún no se han cargado
          if (open && item.children.isEmpty) {
            // Cargar subdirectorios en segundo plano
            widget.onLoadSubdirectories(item);
          }
        });
      },
      // Control visual para mantener el mismo estilo
      tilePadding: const EdgeInsets.symmetric(horizontal: 8.0),
      childrenPadding: const EdgeInsets.only(left: 24.0),
    );
  }
}