import 'package:flutter/material.dart';
import '../../core/media/media_item.dart';
import '../../core/media/media_desktop_service.dart';
import '../../core/media/media_service.dart';

class OrganizerPage extends StatefulWidget {
  const OrganizerPage({super.key});

  @override
  State<OrganizerPage> createState() => _OrganizerPageState();
}

class _OrganizerPageState extends State<OrganizerPage> {
  final MediaService service = MediaDesktopService();
  List<MediaItem> mediaList = [];
  List<MediaItem> selectedItems = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadMedia();
  }

  Future<void> _loadMedia() async {
    setState(() => loading = true);
    mediaList = await service.loadMedia();
    setState(() => loading = false);
  }

  void _toggleSelection(MediaItem item) {
    setState(() {
      if (selectedItems.contains(item)) {
        selectedItems.remove(item);
      } else {
        selectedItems.add(item);
      }
    });
  }

  void _copySelected() {
    // Por ahora solo mostramos un mensaje
    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay archivos seleccionados')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Simulando copiar ${selectedItems.length} archivos al PC...'),
      ),
    );

    // Limpiamos selección
    setState(() => selectedItems.clear());
  }

  void _organizeByMonth() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Simulando organizar archivos por mes...')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Organizador de Fotos PC'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: mediaList.length,
              itemBuilder: (context, index) {
                final item = mediaList[index];
                final selected = selectedItems.contains(item);
                return ListTile(
                  leading: Icon(
                    item.name.endsWith('.mp4')
                        ? Icons.videocam
                        : Icons.photo,
                  ),
                  title: Text(item.name),
                  subtitle: Text(
                      '${item.date.year}-${item.date.month}-${item.date.day}'),
                  trailing: Checkbox(
                    value: selected,
                    onChanged: (value) => _toggleSelection(item),
                  ),
                  onTap: () => _toggleSelection(item),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _copySelected,
                  icon: const Icon(Icons.copy),
                  label: const Text('Copiar seleccionados'),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _organizeByMonth,
                  icon: const Icon(Icons.calendar_month),
                  label: const Text('Organizar por mes'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
