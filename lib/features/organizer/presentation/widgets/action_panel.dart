import 'package:flutter/material.dart';
import 'package:photo_organizer_pc/features/organizer/presentation/view_models/organizer_view_model.dart';
import 'progress_panel.dart';

class ActionPanel extends StatelessWidget {
  final bool isLoading;
  final bool? isConnected;
  final VoidCallback onCheckConnection;
  final VoidCallback onStartScrcpy;
  final VoidCallback onExtractTodayMedia;
  final Function(int year) onCopyAndOrganize;
  final Function(DateTime) onExtractSpecificDateMedia;
  final Function(int year, int month) onCopyMediaByMonth;
  final VoidCallback onExtractTodayMediaFromInternal;
  final Function(DateTime) onExtractSpecificDateFromInternal;
  final OrganizerViewModel viewModel; // Añadido

  const ActionPanel({
    super.key,
    required this.isLoading,
    required this.isConnected,
    required this.onCheckConnection,
    required this.onStartScrcpy,
    required this.onExtractTodayMedia,
    required this.onCopyAndOrganize,
    required this.onExtractSpecificDateMedia,
    required this.onCopyMediaByMonth,
    required this.onExtractTodayMediaFromInternal,
    required this.onExtractSpecificDateFromInternal,
    required this.viewModel, // Añadido
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Panel para tarjeta SD
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📸 Acciones con la tarjeta SD',
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
                        // Botón extraer fotos de hoy desde SD
                        ElevatedButton.icon(
                          onPressed: (isConnected == true && !isLoading)
                              ? onExtractTodayMedia
                              : null,
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Extraer fotos de hoy'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),

                        // Botón copiar de fecha específica desde SD
                        ElevatedButton.icon(
                          onPressed: (isConnected == true && !isLoading)
                              ? () => _showDatePickerDialog(context, isInternal: false)
                              : null,
                          icon: const Icon(Icons.calendar_today),
                          label: const Text('Copiar de fecha específica'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                          ),
                        ),

                        // Botón copiar y organizar por año desde SD
                        Tooltip(
                          message: 'Copia archivos de un año específico desde la SD y los organiza por mes',
                          child: ElevatedButton.icon(
                            onPressed: (isConnected == true && !isLoading)
                                ? () => _showYearPickerDialog(context, isInternal: false)
                                : null,
                            icon: const Icon(Icons.sd_card),
                            label: const Text('Copiar por año'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),

                        // Botón copiar por mes desde SD
                        ElevatedButton.icon(
                          onPressed: (isConnected == true && !isLoading)
                              ? () => _showMonthPickerDialog(context, isInternal: false)
                              : null,
                          icon: const Icon(Icons.sd_card),
                          label: const Text('Copiar por mes'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Panel para almacenamiento interno
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📱 Acciones con almacenamiento interno',
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
                        // Botón extraer fotos de hoy desde interno
                        ElevatedButton.icon(
                          onPressed: (isConnected == true && !isLoading)
                              ? onExtractTodayMediaFromInternal
                              : null,
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Extraer fotos de hoy'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),

                        // Botón copiar de fecha específica desde interno
                        ElevatedButton.icon(
                          onPressed: (isConnected == true && !isLoading)
                              ? () => _showDatePickerDialog(context, isInternal: true)
                              : null,
                          icon: const Icon(Icons.calendar_today),
                          label: const Text('Copiar de fecha específica'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                          ),
                        ),

                        // Botón copiar por año desde interno
                        Tooltip(
                          message: 'Copia archivos de un año específico desde el almacenamiento interno',
                          child: ElevatedButton.icon(
                            onPressed: (isConnected == true && !isLoading)
                                ? () => _showYearPickerDialog(context, isInternal: true)
                                : null,
                            icon: const Icon(Icons.phone_android),
                            label: const Text('Copiar por año'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),

                        // Botón copiar por mes desde interno
                        ElevatedButton.icon(
                          onPressed: (isConnected == true && !isLoading)
                              ? () => _showMonthPickerDialog(context, isInternal: true)
                              : null,
                          icon: const Icon(Icons.phone_android),
                          label: const Text('Copiar por mes'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.cyan,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Panel de herramientas generales
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '⚙️ Herramientas generales',
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
                          onPressed: (isConnected == true && !isLoading)
                              ? onStartScrcpy
                              : null,
                          icon: const Icon(Icons.screen_share),
                          label: const Text('Iniciar scrcpy'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
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
              currentOperation: viewModel.currentOperation ??
                  'Esperando acción...',
              logs: viewModel.operationLogs,
              destinationFolder: viewModel.destinationFolder,
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
      ),
    );
  }

  // ============ DIÁLOGOS ============

  void _showDatePickerDialog(BuildContext context, {required bool isInternal}) {
    showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: isInternal ? Colors.teal : Colors.deepPurple,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    ).then((selectedDate) {
      if (selectedDate != null) {
        if (isInternal) {
          onExtractSpecificDateFromInternal(selectedDate);
        } else {
          onExtractSpecificDateMedia(selectedDate);
        }
      }
    });
  }

  void _showYearPickerDialog(BuildContext context, {required bool isInternal}) {
    final now = DateTime.now();
    final currentYear = now.year;

    showDialog(
      context: context,
      builder: (context) {
        int selectedYear = currentYear;

        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isInternal ? 'Seleccionar año (Interno)' : 'Seleccionar año (SD)',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      Text(
                        isInternal
                            ? '¿De qué año quieres copiar desde el almacenamiento interno?'
                            : '¿De qué año quieres copiar desde la tarjeta SD?',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 16),

                      // Selector de año
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: DropdownButton<int>(
                          isExpanded: true,
                          underline: const SizedBox(),
                          value: selectedYear,
                          onChanged: (value) => setState(() => selectedYear = value!),
                          items: List.generate(10, (index) {
                            final year = currentYear - index;
                            return DropdownMenuItem(
                              value: year,
                              child: Text('$year'),
                            );
                          }),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Información de selección
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isInternal ? Colors.teal.shade50 : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isInternal ? Icons.phone_android : Icons.sd_card,
                              color: isInternal ? Colors.teal : Colors.orange,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isInternal
                                    ? 'Se copiarán fotos/vídeos del año $selectedYear desde el almacenamiento interno'
                                    : 'Se copiarán fotos/vídeos del año $selectedYear desde la tarjeta SD',
                                style: TextStyle(
                                  color: isInternal ? Colors.teal[800] : Colors.orange[800],
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Botones de acción
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancelar'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              if (isInternal) {
                                viewModel.copyFromInternalStorage(year: selectedYear);
                              } else {
                                onCopyAndOrganize(selectedYear);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isInternal ? Colors.teal : Colors.orange,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Copiar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showMonthPickerDialog(BuildContext context, {required bool isInternal}) {
    final now = DateTime.now();
    final currentYear = now.year;

    showDialog(
      context: context,
      builder: (context) => _YearMonthDialog(
        currentYear: currentYear,
        onSelected: isInternal
            ? (year, month) {
          viewModel.copyFromInternalStorageByMonth(year, month);
        }
            : onCopyMediaByMonth,
        title: isInternal ? 'Seleccionar mes (Interno)' : 'Seleccionar mes (SD)',
        buttonText: 'Copiar',
        isInternal: isInternal,
      ),
    );
  }
}

// ============ COMPONENTES REUTILIZABLES ============

class _YearMonthDialog extends StatefulWidget {
  final int currentYear;
  final Function(int, int) onSelected;
  final String title;
  final String buttonText;
  final bool isInternal;

  const _YearMonthDialog({
    required this.currentYear,
    required this.onSelected,
    required this.title,
    required this.buttonText,
    required this.isInternal,
  });

  @override
  State<_YearMonthDialog> createState() => __YearMonthDialogState();
}

class __YearMonthDialogState extends State<_YearMonthDialog> {
  late int selectedYear;
  int? selectedMonth;

  @override
  void initState() {
    super.initState();
    selectedYear = widget.currentYear;
  }

  @override
  Widget build(BuildContext context) {
    final buttonColor = widget.isInternal ? Colors.teal : Colors.indigo;
    final icon = widget.isInternal ? Icons.phone_android : Icons.sd_card;
    final sourceText = widget.isInternal ? 'almacenamiento interno' : 'tarjeta SD';

    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 400,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Selector de año
              _buildYearSelector(),
              const SizedBox(height: 20),

              // Selector de mes
              _buildMonthSelector(buttonColor),
              const SizedBox(height: 16),

              // Información de selección
              if (selectedMonth != null)
                _buildSelectionInfo(buttonColor, icon, sourceText),
              const SizedBox(height: 16),

              // Botones
              _buildActionButtons(buttonColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildYearSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Año:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButton<int>(
            isExpanded: true,
            underline: const SizedBox(),
            value: selectedYear,
            onChanged: (value) {
              setState(() {
                selectedYear = value!;
                selectedMonth = null;
              });
            },
            items: List.generate(10, (index) {
              final year = widget.currentYear - index;
              return DropdownMenuItem(
                value: year,
                child: Text('$year'),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthSelector(Color buttonColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Mes:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          height: 140,
          child: GridView.builder(
            shrinkWrap: true,
            primary: false,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 2.0,
            ),
            itemCount: 12,
            itemBuilder: (context, index) {
              final month = index + 1;
              final monthNames = [
                'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
                'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
              ];

              return InkWell(
                onTap: () => setState(() => selectedMonth = month),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  decoration: BoxDecoration(
                    color: selectedMonth == month
                        ? buttonColor
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selectedMonth == month
                          ? buttonColor
                          : Colors.grey[300]!,
                      width: selectedMonth == month ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          monthNames[index],
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                            color: selectedMonth == month
                                ? Colors.white
                                : Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '($month)',
                          style: TextStyle(
                            fontSize: 10,
                            color: selectedMonth == month
                                ? Colors.white.withOpacity(0.8)
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSelectionInfo(Color buttonColor, IconData icon, String sourceText) {
    final monthNames = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: buttonColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: buttonColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Se copiarán fotos/vídeos de ${selectedMonth!.toString().padLeft(2, '0')} - '
                  '${monthNames[selectedMonth! - 1]} $selectedYear desde $sourceText',
              style: TextStyle(
                color: buttonColor,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Color buttonColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: selectedMonth != null
              ? () {
            Navigator.pop(context);
            widget.onSelected(selectedYear, selectedMonth!);
          }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(widget.buttonText),
        ),
      ],
    );
  }
}