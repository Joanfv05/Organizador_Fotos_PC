import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:photo_organizer_pc/core/adb/adb_service.dart';
import 'package:photo_organizer_pc/features/whatsapp/presentation/view_models/whatsapp_view_model.dart';
import 'package:photo_organizer_pc/features/whatsapp/presentation/widgets/whatsapp_action_panel.dart';
import 'package:photo_organizer_pc/features/whatsapp/presentation/widgets/whatsapp_progress_panel.dart';

class WhatsAppPage extends StatelessWidget {
  const WhatsAppPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => ADBService()),
        ChangeNotifierProvider(
          create: (context) => WhatsAppViewModel(
            adbService: context.read<ADBService>(),
          ),
        ),
      ],
      child: const _WhatsAppPageContent(),
    );
  }
}

class _WhatsAppPageContent extends StatefulWidget {
  const _WhatsAppPageContent();

  @override
  State<_WhatsAppPageContent> createState() => _WhatsAppPageContentState();
}

class _WhatsAppPageContentState extends State<_WhatsAppPageContent> {
  late WhatsAppViewModel viewModel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      viewModel = context.read<WhatsAppViewModel>();
      viewModel.addListener(_onViewModelChanged);
      viewModel.checkConnection(); // Verificar conexión automáticamente
    });
  }

  void _onViewModelChanged() {
    if (!mounted) return;
    if (viewModel.errorMessage != null) {
      _showMessage(context, viewModel.errorMessage!, error: true);
      viewModel.clearMessages();
    }
    if (viewModel.successMessage != null) {
      _showMessage(context, viewModel.successMessage!);
      viewModel.clearMessages();
    }
  }

  @override
  void dispose() {
    viewModel.removeListener(_onViewModelChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<WhatsAppViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('📱 WhatsApp - Fotos y Videos'),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Verificar conexión',
            onPressed: viewModel.isLoading ? null : viewModel.checkConnection,
          ),
        ],
      ),
      body: Column(
        children: [
          // Estado de conexión
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: viewModel.isDeviceConnected == true
                ? Colors.green.shade50
                : Colors.red.shade50,
            child: Row(
              children: [
                Icon(
                  viewModel.isDeviceConnected == true
                      ? Icons.check_circle
                      : Icons.error,
                  color: viewModel.isDeviceConnected == true
                      ? Colors.green
                      : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  viewModel.isDeviceConnected == true
                      ? 'Dispositivo conectado'
                      : 'Dispositivo no conectado',
                  style: TextStyle(
                    color: viewModel.isDeviceConnected == true
                        ? Colors.green[800]
                        : Colors.red[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (viewModel.isDeviceConnected == true)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      '✅ Listo',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),

          // Contenido principal
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Panel de acciones de WhatsApp
                  WhatsAppActionPanel(
                    isConnected: viewModel.isDeviceConnected,
                    isLoading: viewModel.isLoading,
                    onCopyImagesByYear: (year) =>
                        viewModel.copyWhatsAppImagesByYear(year: year),
                    onCopyVideosByYear: (year) =>
                        viewModel.copyWhatsAppVideosByYear(year: year),
                    onCopyImagesByMonth: (year, month) =>
                        viewModel.copyWhatsAppImagesByMonth(year, month),
                    onCopyVideosByMonth: (year, month) =>
                        viewModel.copyWhatsAppVideosByMonth(year, month),
                    onCopyImagesByDate: (date) =>
                        viewModel.copyWhatsAppImagesByDate(date),
                    onCopyVideosByDate: (date) =>
                        viewModel.copyWhatsAppVideosByDate(date),
                  ),

                  const SizedBox(height: 24),

                  // Panel de progreso
                  WhatsAppProgressPanel(
                    progress: viewModel.currentProgress,
                    isActive: viewModel.isLoading,
                    currentOperation: viewModel.currentOperation ??
                        'Esperando acción...',
                    logs: viewModel.operationLogs,
                    destinationFolder: viewModel.destinationFolder,
                  ),

                  // Botón limpiar logs
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
            ),
          ),
        ],
      ),
    );
  }

  void _showMessage(BuildContext context, String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}