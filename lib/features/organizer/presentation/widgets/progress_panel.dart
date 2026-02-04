import 'package:flutter/material.dart';
import 'package:clipboard/clipboard.dart';
import 'package:photo_organizer_pc/features/organizer/domain/models/transfer_progress.dart';
import 'dart:io';

class ProgressPanel extends StatelessWidget {
  final TransferProgress? progress;
  final bool isActive;
  final String currentOperation;
  final List<String> logs;
  final String? destinationFolder;
  final String? lastDestinationPath; // NUEVO: para mostrar ruta guardada

  const ProgressPanel({
    super.key,
    this.progress,
    required this.isActive,
    required this.currentOperation,
    required this.logs,
    this.destinationFolder,
    this.lastDestinationPath, // NUEVO parámetro
  });

  @override
  Widget build(BuildContext context) {
    // Determinar qué ruta mostrar
    final String? displayedPath = destinationFolder ?? lastDestinationPath;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(8.0),
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

            // Información de carpeta destino con botón de copiar
            // MODIFICADO: Mostrar siempre si hay ruta disponible
            if (displayedPath != null) ...[
              _buildDestinationFolderSection(context, displayedPath),
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

  // MODIFICADO: Aceptar la ruta como parámetro
  Widget _buildDestinationFolderSection(BuildContext context, String path) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado con icono y botón
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.folder, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    // MODIFICADO: Distinguir entre operación actual y última
                    destinationFolder != null
                        ? '📂 Carpeta destino actual'
                        : '💾 Última carpeta destino',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),

              // Botón para copiar ruta
              Tooltip(
                message: 'Copiar ruta al portapapeles',
                child: InkWell(
                  onTap: () {
                    _copyPathToClipboard(context, path);
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.content_copy, size: 14, color: Colors.white),
                        SizedBox(width: 6),
                        Text(
                          'Copiar ruta',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Ruta completa con posibilidad de seleccionar
          GestureDetector(
            onLongPress: () {
              _copyPathToClipboard(context, path);
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Ruta completa
                        SelectableText(
                          path,
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'Monospace',
                            color: Colors.black87,
                          ),
                          maxLines: 3,
                          minLines: 1,
                        ),

                        // Separador
                        const SizedBox(height: 6),
                        const Divider(height: 1, color: Colors.grey),
                        const SizedBox(height: 6),

                        // Información adicional
                        Row(
                          children: [
                            Icon(Icons.info_outline, size: 12, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              // MODIFICADO: Mensaje diferente según estado
                              destinationFolder != null
                                  ? 'Presiona y mantén para copiar'
                                  : 'Ruta guardada de la última operación',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Icono de acceso rápido
                  Tooltip(
                    message: 'Abrir en explorador de archivos',
                    child: IconButton(
                      icon: const Icon(Icons.open_in_new, size: 16),
                      color: Colors.blue,
                      onPressed: () {
                        _openInFileExplorer(path);
                      },
                      padding: const EdgeInsets.all(2),
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
          color: Colors.grey.shade50,
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

  // ============ MÉTODOS AUXILIARES PARA COPIAR RUTA ============

  void _copyPathToClipboard(BuildContext context, String path) {
    FlutterClipboard.copy(path).then((_) {
      // Mostrar snackbar de confirmación
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✅ Ruta copiada al portapapeles'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error al copiar: $error'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    });
  }

  void _openInFileExplorer(String path) async {
    try {
      // Verificar si la carpeta existe
      final dir = Directory(path);
      bool exists = await dir.exists();

      String pathToOpen = exists ? path : dir.parent.path;

      // Método cross-platform para abrir el explorador de archivos
      if (Platform.isWindows) {
        await Process.run('explorer', [pathToOpen.replaceAll('/', '\\')]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [pathToOpen]);
      } else if (Platform.isMacOS) {
        await Process.run('open', [pathToOpen]);
      }

      print('📂 Abriendo explorador en: $pathToOpen');
    } catch (e) {
      print('❌ Error al abrir explorador: $e');

      // Mostrar mensaje al usuario (opcional)
      // Puedes agregar un ScaffoldMessenger aquí si quieres
    }
  }
}