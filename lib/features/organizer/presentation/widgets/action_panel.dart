import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:photo_organizer_pc/features/organizer/presentation/view_models/organizer_view_model.dart';
import 'progress_panel.dart';

class ActionPanel extends StatelessWidget {
  final bool isLoading;
  final bool? isConnected;
  final VoidCallback onCheckConnection;
  final VoidCallback onStartScrcpy;
  final VoidCallback onExtractTodayMedia;
  final VoidCallback onCopyAndOrganize;

  const ActionPanel({
    super.key,
    required this.isLoading,
    required this.isConnected,
    required this.onCheckConnection,
    required this.onStartScrcpy,
    required this.onExtractTodayMedia,
    required this.onCopyAndOrganize,
  });

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<OrganizerViewModel>();

    return Padding(
      padding: const EdgeInsets.all(32),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Sección de botones
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Acciones del dispositivo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      // Botón verificar conexión
                      ElevatedButton.icon(
                        onPressed: isLoading ? null : onCheckConnection,
                        icon: const Icon(Icons.usb),
                        label: const Text('Verificar conexión'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),

                      // Botón iniciar scrcpy
                      ElevatedButton.icon(
                        onPressed: (isConnected == true && !isLoading) ? onStartScrcpy : null,
                        icon: const Icon(Icons.screen_share),
                        label: const Text('Iniciar scrcpy'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                        ),
                      ),

                      // Botón extraer fotos de hoy
                      ElevatedButton.icon(
                        onPressed: (isConnected == true && !isLoading) ? onExtractTodayMedia : null,
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Extraer fotos de hoy'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),

                      // Botón copiar y organizar (con tooltip)
                      Tooltip(
                        message: 'Copia archivos desde la SD y los organiza por mes',
                        child: ElevatedButton.icon(
                          onPressed: (isConnected == true && !isLoading) ? onCopyAndOrganize : null,
                          icon: const Icon(Icons.content_copy),
                          label: const Text('Copiar y organizar media'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Estado de conexión
                  if (isConnected != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isConnected! ? Colors.green.shade50 : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isConnected! ? Colors.green.shade200 : Colors.red.shade200,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isConnected! ? Icons.check_circle : Icons.error,
                            color: isConnected! ? Colors.green : Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isConnected!
                                ? 'Dispositivo CONECTADO'
                                : 'Dispositivo DESCONECTADO',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isConnected! ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Panel de progreso
          ProgressPanel(
            progress: viewModel.currentProgress,
            isActive: viewModel.isActionLoading,
            currentOperation: viewModel.currentOperation ?? 'Esperando acción...',
            logs: viewModel.operationLogs,
          ),

          // Botón para limpiar logs
          if (viewModel.operationLogs.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => viewModel.clearLogs(),
                  icon: const Icon(Icons.delete_sweep, size: 16),
                  label: const Text('Limpiar registro'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                  ),
                ),
              ),
            ),
        ],
      ),
    )
    );
  }
}