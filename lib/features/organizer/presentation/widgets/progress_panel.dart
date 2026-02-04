import 'package:flutter/material.dart';
import 'package:photo_organizer_pc/features/organizer/domain/models/transfer_progress.dart';
import 'dart:io';
import 'dart:async';
import 'package:flutter/services.dart';

class ProgressPanel extends StatelessWidget {
  final TransferProgress? progress;
  final bool isActive;
  final String currentOperation;
  final List<String> logs;
  final String? destinationFolder;
  final String? lastDestinationPath;

  const ProgressPanel({
    super.key,
    this.progress,
    required this.isActive,
    required this.currentOperation,
    required this.logs,
    this.destinationFolder,
    this.lastDestinationPath,
  });

  @override
  Widget build(BuildContext context) {
    final String? displayedPath = destinationFolder ?? lastDestinationPath;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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

            if (displayedPath != null) ...[
              _buildDestinationFolderSection(context, displayedPath),
              const SizedBox(height: 12),
            ],

            if (isActive && progress != null) ...[
              _buildProgressSection(progress!),
              const SizedBox(height: 16),
            ],

            if (logs.isNotEmpty) ...[
              _buildLogsSection(),
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

    if (progress?.type == null) {
      return const Icon(Icons.sync, color: Colors.blue, size: 28);
    }

    switch (progress!.type!) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.folder, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Text(
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

                        const SizedBox(height: 6),
                        const Divider(height: 1, color: Colors.grey),
                        const SizedBox(height: 6),

                        Row(
                          children: [
                            Icon(Icons.info_outline, size: 12, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
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

  Widget _buildProgressSection(TransferProgress progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: progress.percentage / 100,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(
            _getColorForType(progress.type ?? TransferType.scanning),
          ),
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
                    progress.statusText,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _getColorForType(progress.type ?? TransferType.scanning),
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
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 16),

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
    }
  }

  // ============ MÉTODO ACTUALIZADO PARA COPIAR AL PORTAPAPELES ============
  void _copyPathToClipboard(BuildContext context, String path) async {
    try {
      // Intentar métodos nativos primero
      final success = await _copyUsingNativeMethods(path);

      if (!success) {
        // Fallback al portapapeles de Flutter
        await Clipboard.setData(ClipboardData(text: path));
      }

      if (!context.mounted) return;

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
    } catch (error) {
      debugPrint('Error al copiar al portapapeles: $error');

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('❌ Error al copiar la ruta'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // Método nativo para copiar al portapapeles
  Future<bool> _copyUsingNativeMethods(String text) async {
    try {
      if (Platform.isWindows) {
        // Windows - Usar el comando clip
        final process = await Process.start('cmd', ['/c', 'echo', text, '|', 'clip']);
        final exitCode = await process.exitCode;
        return exitCode == 0;
      } else if (Platform.isLinux) {
        // Linux - Probar múltiples métodos
        return await _copyLinux(text);
      } else if (Platform.isMacOS) {
        // macOS - Usar pbcopy
        final process = await Process.start('bash', ['-c', 'echo "$text" | pbcopy']);
        final exitCode = await process.exitCode;
        return exitCode == 0;
      } else {
        // Para otras plataformas, usar el método de Flutter
        return false;
      }
    } catch (e) {
      debugPrint('Error en método nativo: $e');
      return false;
    }
  }

  // Método específico para Linux
  Future<bool> _copyLinux(String text) async {
    try {
      // Lista de comandos de portapapeles a probar en orden
      final clipboardCommands = [
        ['xclip', '-selection', 'clipboard'],
        ['wl-copy'],
        ['xsel', '--clipboard', '--input'],
      ];

      for (final command in clipboardCommands) {
        try {
          // Verificar si el comando existe
          final whichProcess = await Process.run('which', [command[0]]);
          if (whichProcess.exitCode != 0) {
            continue; // Comando no encontrado, probar siguiente
          }

          // Ejecutar el comando de copia
          final process = await Process.start(
              'bash',
              ['-c', 'echo "$text" | ${command.join(" ")}']
          );
          final exitCode = await process.exitCode;

          if (exitCode == 0) {
            debugPrint('Copiado usando: ${command[0]}');
            return true;
          }
        } catch (e) {
          // Continuar con el siguiente comando
          continue;
        }
      }

      // Ningún comando funcionó
      return false;
    } catch (e) {
      debugPrint('Error en _copyLinux: $e');
      return false;
    }
  }

  void _openInFileExplorer(String path) async {
    try {
      final dir = Directory(path);
      bool exists = await dir.exists();

      String pathToOpen = exists ? path : dir.parent.path;

      if (Platform.isWindows) {
        await Process.run('explorer', [pathToOpen.replaceAll('/', '\\')]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [pathToOpen]);
      } else if (Platform.isMacOS) {
        await Process.run('open', [pathToOpen]);
      }

      debugPrint('📂 Abriendo explorador en: $pathToOpen');
    } catch (e) {
      debugPrint('❌ Error al abrir explorador: $e');
    }
  }
}