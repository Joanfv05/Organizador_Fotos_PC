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
  final Function(int year) onCopyAndOrganize;
  final Function(DateTime) onExtractSpecificDateMedia;
  final Function(int year, int month) onCopyMediaByMonth; // NUEVO parámetro

  const ActionPanel({
    super.key,
    required this.isLoading,
    required this.isConnected,
    required this.onCheckConnection,
    required this.onStartScrcpy,
    required this.onExtractTodayMedia,
    required this.onCopyAndOrganize,
    required this.onExtractSpecificDateMedia,
    required this.onCopyMediaByMonth, // NUEVO parámetro
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

                        // Botón extraer fotos de hoy
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

                        // Botón copiar y organizar (con tooltip)
                        Tooltip(
                          message: 'Copia archivos de un año específico desde la SD y los organiza por mes',
                          child: ElevatedButton.icon(
                            onPressed: (isConnected == true && !isLoading)
                                ? () => _showYearPickerDialog(context)  // ← NUEVO: Mostrar selector de año
                                : null,
                            icon: const Icon(Icons.content_copy),
                            label: const Text('Copiar y organizar media por año'),  // ← TEXTO ACTUALIZADO
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),

                        // Botón copiar de fecha específica
                        ElevatedButton.icon(
                          onPressed: (isConnected == true && !isLoading)
                              ? () => _showDatePickerDialog(context)
                              : null,
                          icon: const Icon(Icons.calendar_today),
                          label: const Text('Copiar de fecha específica'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                          ),
                        ),

                        // NUEVO: Botón copiar fotos/videos de mes específico
                        ElevatedButton.icon(
                          onPressed: (isConnected == true && !isLoading)
                              ? () => _showMonthPickerDialog(context)
                              : null,
                          icon: const Icon(Icons.calendar_month),
                          label: const Text('Copiar de mes específico'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
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
                          color: isConnected! ? Colors.green.shade50 : Colors
                              .red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isConnected! ? Colors.green.shade200 : Colors
                                .red.shade200,
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

  // Método para mostrar el diálogo de fecha:
  void _showDatePickerDialog(BuildContext context) {
    showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.deepPurple,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    ).then((selectedDate) {
      if (selectedDate != null) {
        onExtractSpecificDateMedia(selectedDate);
      }
    });
  }

  // Método para mostrar diálogo de selección de año
  void _showYearPickerDialog(BuildContext context) {
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
                      const Text(
                        'Seleccionar año',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        '¿De qué año quieres copiar y organizar las fotos?',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 16),

                      // Selección de año
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
                            });
                          },
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

                      // Mostrar selección actual
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, color: Colors.orange, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Se copiarán fotos y vídeos del año $selectedYear',
                                style: TextStyle(
                                  color: Colors.orange[800],
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
                              onCopyAndOrganize(selectedYear);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Seleccionar'),
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
    ).then((_) {
      // El ViewModel ya manejará la llamada al repositorio con el año seleccionado
      // Necesitarás modificar el ViewModel para almacenar el año seleccionado
    });
  }

// Método para mostrar el diálogo de selección de mes
  void _showMonthPickerDialog(BuildContext context) {
    final now = DateTime.now();
    final currentYear = now.year;

    // Mostrar diálogo para seleccionar año
    showDialog(
      context: context,
      builder: (context) {
        int selectedYear = currentYear;
        int? selectedMonth;

        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 400,
                  maxHeight: MediaQuery
                      .of(context)
                      .size
                      .height * 0.8, // Aumentamos a 80%
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Seleccionar mes',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Selección de año
                      const Text('Año:', style: TextStyle(fontWeight: FontWeight
                          .bold)),
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
                          // Sin línea inferior
                          value: selectedYear,
                          onChanged: (value) {
                            setState(() {
                              selectedYear = value!;
                              selectedMonth = null;
                            });
                          },
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

                      // Selección de mes - Ahora con altura fija y scroll
                      const Text('Mes:', style: TextStyle(fontWeight: FontWeight
                          .bold)),
                      const SizedBox(height: 8),

                      // Opción 1: GridView con scroll (recomendada)
                      SizedBox(
                        height: 140,
                        // Altura fija suficiente para 12 meses en 3 filas
                        child: GridView.builder(
                          shrinkWrap: true,
                          primary: false,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4, // 4 columnas
                            mainAxisSpacing: 4,
                            crossAxisSpacing: 4,
                            childAspectRatio: 2.0, // Cuadrados perfectos
                          ),
                          itemCount: 12,
                          itemBuilder: (context, index) {
                            final month = index + 1;
                            final monthNames = [
                              'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
                              'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
                            ];

                            return InkWell(
                              onTap: () {
                                setState(() {
                                  selectedMonth = month;
                                });
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: selectedMonth == month
                                      ? Colors.indigo
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: selectedMonth == month
                                        ? Colors.indigo
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

                      const SizedBox(height: 16),

                      // Mostrar selección actual
                      if (selectedMonth != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.indigo.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today, color: Colors.indigo,
                                  size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Seleccionado: ${selectedMonth!.toString()
                                      .padLeft(2, '0')} - ${[
                                    'Enero',
                                    'Febrero',
                                    'Marzo',
                                    'Abril',
                                    'Mayo',
                                    'Junio',
                                    'Julio',
                                    'Agosto',
                                    'Septiembre',
                                    'Octubre',
                                    'Noviembre',
                                    'Diciembre'
                                  ][selectedMonth! - 1]} $selectedYear',
                                  style: TextStyle(
                                    color: Colors.indigo[800],
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
                            onPressed: selectedMonth != null
                                ? () {
                              Navigator.pop(context);
                              onCopyMediaByMonth(selectedYear, selectedMonth!);
                            }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Seleccionar'),
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
}