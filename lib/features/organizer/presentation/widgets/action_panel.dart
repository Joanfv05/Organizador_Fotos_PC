import 'package:flutter/material.dart';

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
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElevatedButton.icon(
            onPressed: isLoading ? null : onCheckConnection,
            icon: const Icon(Icons.usb),
            label: const Text('Verificar conexión'),
          ),
          const SizedBox(height: 16),

          ElevatedButton.icon(
            onPressed: (isConnected == true) ? onStartScrcpy : null,
            icon: const Icon(Icons.screen_share),
            label: const Text('Iniciar scrcpy'),
          ),
          const SizedBox(height: 16),

          ElevatedButton.icon(
            onPressed: (isConnected == true) ? onExtractTodayMedia : null,
            icon: const Icon(Icons.photo_library),
            label: const Text('Extraer fotos de hoy'),
          ),
          const SizedBox(height: 16),

          Tooltip(
            message: 'Copia archivos desde la SD y los organiza por mes',
            child: ElevatedButton.icon(
              onPressed: (isConnected == true) ? onCopyAndOrganize : null,
              icon: const Icon(Icons.content_copy),
              label: const Text('Copiar y organizar media'),
            ),
          ),

          const SizedBox(height: 24),

          if (isConnected != null)
            Text(
              isConnected!
                  ? 'Estado: CONECTADO'
                  : 'Estado: DESCONECTADO',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isConnected! ? Colors.green : Colors.red,
              ),
            ),
        ],
      ),
    );
  }
}
