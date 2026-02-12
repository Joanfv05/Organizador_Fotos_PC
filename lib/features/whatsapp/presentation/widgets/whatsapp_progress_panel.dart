import 'package:flutter/material.dart';
import 'package:photo_organizer_pc/features/organizer/domain/models/transfer_progress.dart';
import 'dart:io';
import 'package:flutter/services.dart';

class WhatsAppProgressPanel extends StatelessWidget {
  final TransferProgress? progress;
  final bool isActive;
  final String currentOperation;
  final List<String> logs;
  final String? destinationFolder;

  const WhatsAppProgressPanel({
    super.key,
    this.progress,
    required this.isActive,
    required this.currentOperation,
    required this.logs,
    this.destinationFolder,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            if (destinationFolder != null) _buildDestinationSection(context),
            if (isActive && progress != null) _buildProgressSection(),
            if (logs.isNotEmpty) _buildLogsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        _buildStatusIcon(),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isActive ? '🔄 Operación en curso' : '✅ Listo',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                currentOperation,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusIcon() {
    if (!isActive) {
      return const Icon(Icons.check_circle, color: Colors.green, size: 28);
    }
    return const Icon(Icons.download, color: Colors.green, size: 28);
  }

  Widget _buildDestinationSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.folder, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '📂 Carpeta destino',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green[800],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              _buildCopyButton(context),
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onLongPress: () => _copyPathToClipboard(context, destinationFolder!),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      destinationFolder!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'Monospace',
                      ),
                      maxLines: 2,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.open_in_new, size: 16),
                    color: Colors.green,
                    onPressed: () => _openInFileExplorer(destinationFolder!),
                    padding: const EdgeInsets.all(2),
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCopyButton(BuildContext context) {
    return Tooltip(
      message: 'Copiar ruta',
      child: InkWell(
        onTap: () => _copyPathToClipboard(context, destinationFolder!),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Row(
            children: [
              Icon(Icons.content_copy, size: 14, color: Colors.white),
              SizedBox(width: 6),
              Text(
                'Copiar ruta',
                style: TextStyle(fontSize: 12, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: progress!.percentage / 100,
          backgroundColor: Colors.grey[200],
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
          minHeight: 10,
          borderRadius: BorderRadius.circular(5),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    progress!.statusText,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    progress!.fileInfo,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${progress!.current}/${progress!.total}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${progress!.percentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLogsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '📝 Registro de actividad',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            Chip(
              label: Text('${logs.length}'),
              backgroundColor: Colors.grey[100],
              labelStyle: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 100,
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            reverse: true,
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[logs.length - 1 - index];
              Color textColor = Colors.grey[700]!;

              if (log.contains('✅')) textColor = Colors.green;
              else if (log.contains('❌')) textColor = Colors.red;
              else if (log.contains('📥')) textColor = Colors.blue;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Text(
                  log,
                  style: TextStyle(fontSize: 11, color: textColor),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _copyPathToClipboard(BuildContext context, String path) async {
    try {
      await Clipboard.setData(ClipboardData(text: path));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✅ Ruta copiada al portapapeles'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint('Error copiando: $e');
    }
  }

  void _openInFileExplorer(String path) async {
    try {
      if (Platform.isWindows) {
        await Process.run('explorer', [path.replaceAll('/', '\\')]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [path]);
      } else if (Platform.isMacOS) {
        await Process.run('open', [path]);
      }
    } catch (e) {
      debugPrint('Error abriendo explorador: $e');
    }
  }
}