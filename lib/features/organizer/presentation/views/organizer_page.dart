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

class _OrganizerPageContent extends StatelessWidget {
  const _OrganizerPageContent();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<OrganizerViewModel>();

    // Mostrar mensajes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (viewModel.errorMessage != null) {
        _showMessage(context, viewModel.errorMessage!, error: true);
        viewModel.clearMessages();
      }
      if (viewModel.successMessage != null) {
        _showMessage(context, viewModel.successMessage!);
        viewModel.clearMessages();
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Organizador de Fotos PC')),
      body: Row(
        children: [
          // Panel del árbol de directorios (30%)
          Flexible(
            flex: 3,
            child: DirectoryTree(
              tree: viewModel.tree,
              isLoading: viewModel.isTreeLoading,
              isConnected: viewModel.isDeviceConnected,
              onLoadSubdirectories: (item) =>
                  viewModel.loadSubdirectories(item),
            ),
          ),

          // Panel de acciones (70%)
          Flexible(
            flex: 7,
            child: ActionPanel(
              isLoading: viewModel.isActionLoading,
              isConnected: viewModel.isDeviceConnected,
              onCheckConnection: () => viewModel.checkConnection(),
              onStartScrcpy: () => viewModel.startScrcpy(),
              onExtractTodayMedia: () => viewModel.extractTodayMedia(),
              onCopyAndOrganize: (year) => viewModel.copyAndOrganizeMedia(year: year),
              onExtractSpecificDateMedia: (date) => viewModel.extractSpecificDateMedia(date),
              onCopyMediaByMonth: (year, month) => viewModel.copyMediaByMonth(year, month),
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
        backgroundColor: error ? Colors.red : Colors.green,
      ),
    );
  }
}