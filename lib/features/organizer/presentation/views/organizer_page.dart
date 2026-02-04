import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:photo_organizer_pc/core/adb/adb_service.dart';
import 'package:photo_organizer_pc/core/adb/media_extractor.dart';
import 'package:photo_organizer_pc/features/organizer/data/repositories/organizer_repository.dart';
import 'package:photo_organizer_pc/features/organizer/presentation/view_models/organizer_view_model.dart';
import 'package:photo_organizer_pc/features/organizer/presentation/widgets/directory_tree.dart';
import 'package:photo_organizer_pc/features/organizer/presentation/widgets/action_panel.dart';

class OrganizerPage extends StatelessWidget {
  const OrganizerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => ADBService()),
        Provider(create: (_) => MediaExtractorService()),
        Provider(
          create: (context) => OrganizerRepository(
            adbService: context.read<ADBService>(),
            extractorService: context.read<MediaExtractorService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => OrganizerViewModel(
            repository: context.read<OrganizerRepository>(),
          ),
        ),
      ],
      child: const _OrganizerPageContent(),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                               PAGE CONTENT                                 */
/* -------------------------------------------------------------------------- */

class _OrganizerPageContent extends StatefulWidget {
  const _OrganizerPageContent();

  @override
  State<_OrganizerPageContent> createState() => _OrganizerPageContentState();
}

class _OrganizerPageContentState extends State<_OrganizerPageContent> {
  late OrganizerViewModel viewModel;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      viewModel = context.read<OrganizerViewModel>();
      viewModel.addListener(_onViewModelChanged);
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
    final viewModel = context.watch<OrganizerViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Organizador de Fotos PC'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Información del dispositivo',
            onPressed: () => _showDeviceInfoDialog(context, viewModel),
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Ayuda',
            onPressed: () => _showHelpDialog(context),
          ),
        ],
      ),
      body: Row(
        children: [
          /* ----------------------- PANEL IZQUIERDO ----------------------- */
          Flexible(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(right: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      border: Border(
                          bottom: BorderSide(color: Colors.grey.shade300)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '📁 Directorios del dispositivo',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        _buildConnectionBadge(viewModel),
                      ],
                    ),
                  ),
                  Expanded(
                    child: DirectoryTree(
                      tree: viewModel.tree,
                      isLoading: viewModel.isTreeLoading,
                      isConnected: viewModel.isDeviceConnected,
                      onLoadSubdirectories: viewModel.loadSubdirectories,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: Colors.grey.shade300)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Refrescar'),
                          onPressed: viewModel.isTreeLoading
                              ? null
                              : viewModel.checkConnection,
                        ),
                        if (viewModel.isTreeLoading)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          /* ----------------------- PANEL DERECHO ----------------------- */
          Flexible(
            flex: 7,
            child: ActionPanel(
              isLoading: viewModel.isActionLoading,
              isConnected: viewModel.isDeviceConnected,
              onCheckConnection: viewModel.checkConnection,
              onStartScrcpy: viewModel.startScrcpy,
              onExtractTodayMedia: viewModel.extractTodayMedia,
              onCopyAndOrganize: (year) =>
                  viewModel.copyAndOrganizeMedia(year: year),
              onExtractSpecificDateMedia: viewModel.extractSpecificDateMedia,
              onCopyMediaByMonth: viewModel.copyMediaByMonth,
            ),
          ),
        ],
      ),
      // Se ha eliminado el FloatingActionButton completamente
    );
  }

  /* -------------------------------------------------------------------------- */
  /*                                   UI                                       */
  /* -------------------------------------------------------------------------- */

  Widget _buildConnectionBadge(OrganizerViewModel vm) {
    final connected = vm.isDeviceConnected == true;

    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: connected ? Colors.green.shade100 : Colors.red.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              connected ? Icons.check_circle : Icons.error,
              size: 14,
              color: connected ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 4),
            Text(
              connected ? 'Conectado' : 'Desconectado',
              style: TextStyle(
                fontSize: 12,
                color: connected ? Colors.green[800] : Colors.red[800],
              ),
            ),
          ],
        )
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

  /* ---------------------------- DIALOGS ---------------------------- */

  void _showDeviceInfoDialog(BuildContext context, OrganizerViewModel vm) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Información del dispositivo'),
        content: SingleChildScrollView(
          child: Text(vm.statusSummary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ayuda'),
        content: const SingleChildScrollView(
          child: Text(
            'Conecta tu móvil con USB y activa la depuración USB.\n'
                'Luego usa las acciones para copiar y organizar tus fotos.\n\n'
                'Funcionalidades disponibles:\n'
                '• Extraer fotos de hoy\n'
                '• Copiar y organizar por año\n'
                '• Extraer fotos de una fecha específica\n'
                '• Copiar fotos por mes específico',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}