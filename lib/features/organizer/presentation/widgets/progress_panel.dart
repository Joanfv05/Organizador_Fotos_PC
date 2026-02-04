import 'package:flutter/material.dart';
import 'package:photo_organizer_pc/features/organizer/domain/models/transfer_progress.dart';

class ProgressPanel extends StatelessWidget {
  final TransferProgress? progress;
  final bool isActive;
  final String currentOperation;
  final List<String> logs;
  final String? destinationFolder;

  const ProgressPanel({
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título y estado
            Row(
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
            ),

            const SizedBox(height: 16),

            // Información de carpeta destino
            if (destinationFolder != null) ...[
              _buildInfoCard(
                icon: Icons.folder,
                title: 'Carpeta destino',
                content: destinationFolder!,
                color: Colors.blue.shade50,
              ),
              const SizedBox(height: 12),
            ],

            // Barra de progreso (solo si hay operación activa)
            if (isActive && progress != null) ...[
              _buildProgressSection(progress!),
              const SizedBox(height: 16),
            ],

            // Panel de logs
            if (logs.isNotEmpty) ...[
              _buildLogsSection(),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    if (!isActive) {
      return const Icon(Icons.check_circle, color: Colors.green, size: 28);
    }

    switch (progress?.type) {
      case TransferType.pull:
        return const Icon(Icons.download, color: Colors.blue, size: 28);
      case TransferType.push:
        return const Icon(Icons.upload, color: Colors.green, size: 28);
      case TransferType.organizing:
        return const Icon(Icons.sort, color: Colors.orange, size: 28);
      case TransferType.scanning:
        return const Icon(Icons.search, color: Colors.purple, size: 28);
      default:
        return const Icon(Icons.sync, color: Colors.blue, size: 28);
    }
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(TransferProgress progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Barra de progreso
        LinearProgressIndicator(
          value: progress.percentage / 100,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(
            _getColorForType(progress.type),
          ),
          minHeight: 10,
          borderRadius: BorderRadius.circular(5),
        ),

        const SizedBox(height: 8),

        // Información de progreso
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  progress.statusText,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _getColorForType(progress.type),
                  ),
                ),
                if (progress.detailedInfo.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    progress.detailedInfo,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                  ),
                ],
              ],
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${progress.current}/${progress.total} archivos',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${progress.percentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (progress.timeInfo != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    progress.timeInfo!,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Archivo actual
        _buildInfoCard(
            icon: Icons.insert_drive_file,
            title: 'Archivo actual',
            content: progress.fileInfo,
            color: Colors.grey.shade50),
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
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Chip(
              label: Text('${logs.length}'),
              backgroundColor: Colors.grey[100],
              labelStyle: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Lista de logs
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
              final logIndex = logs.length - 1 - index;
              final log = logs[logIndex];

              Color textColor = Colors.grey[700]!;
              IconData? icon;

              if (log.toLowerCase().contains('error') ||
                  log.toLowerCase().contains('fallo')) {
                textColor = Colors.red;
                icon = Icons.error_outline;
              } else if (log.contains('✅') ||
                  log.toLowerCase().contains('completado') ||
                  log.toLowerCase().contains('exitosamente')) {
                textColor = Colors.green;
                icon = Icons.check_circle_outline;
              } else if (log.contains('📁') ||
                  log.toLowerCase().contains('carpeta')) {
                textColor = Colors.blue;
                icon = Icons.folder;
              } else if (log.contains('📷') ||
                  log.toLowerCase().contains('foto') ||
                  log.toLowerCase().contains('imagen')) {
                textColor = Colors.purple;
                icon = Icons.photo;
              }

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 12, color: textColor),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text(
                        log,
                        style: TextStyle(
                          fontSize: 11,
                          color: textColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Color _getColorForType(TransferType type) {
    switch (type) {
      case TransferType.pull:
        return Colors.blue;
      case TransferType.push:
        return Colors.green;
      case TransferType.organizing:
        return Colors.orange;
      case TransferType.scanning:
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }
}