import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class WhatsAppActionPanel extends StatelessWidget {
  final bool? isConnected;
  final bool isLoading;
  final Function(int year) onCopyImagesByYear;
  final Function(int year) onCopyVideosByYear;
  final Function(int year, int month) onCopyImagesByMonth;
  final Function(int year, int month) onCopyVideosByMonth;
  final Function(DateTime) onCopyImagesByDate;
  final Function(DateTime) onCopyVideosByDate;

  const WhatsAppActionPanel({
    super.key,
    required this.isConnected,
    required this.isLoading,
    required this.onCopyImagesByYear,
    required this.onCopyVideosByYear,
    required this.onCopyImagesByMonth,
    required this.onCopyVideosByMonth,
    required this.onCopyImagesByDate,
    required this.onCopyVideosByDate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cabecera
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: FaIcon(
                  FontAwesomeIcons.whatsapp,
                  size: 32,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WhatsApp Media',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Copia y organiza tus fotos y vídeos de WhatsApp',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Panel de Imágenes
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.photo, color: Colors.purple),
                    SizedBox(width: 8),
                    Text(
                      '📸 Imágenes de WhatsApp',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildButtonGrid(
                  context,
                  isImage: true,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Panel de Vídeos
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.video_library, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      '🎥 Vídeos de WhatsApp',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildButtonGrid(
                  context,
                  isImage: false,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildButtonGrid(BuildContext context, {required bool isImage}) {
    final color = isImage ? Colors.purple : Colors.blue;
    final icon = isImage ? Icons.photo : Icons.video_library;
    final type = isImage ? 'imágenes' : 'vídeos';
    final onYear = isImage ? onCopyImagesByYear : onCopyVideosByYear;
    final onMonth = isImage ? onCopyImagesByMonth : onCopyVideosByMonth;
    final onDate = isImage ? onCopyImagesByDate : onCopyVideosByDate;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        // Por año
        ElevatedButton.icon(
          onPressed: (isConnected == true && !isLoading)
              ? () => _showYearPickerDialog(context, type, onYear)
              : null,
          icon: Icon(icon),
          label: Text('Por año'),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),

        // Por mes
        ElevatedButton.icon(
          onPressed: (isConnected == true && !isLoading)
              ? () => _showMonthPickerDialog(context, type, onMonth)
              : null,
          icon: Icon(icon),
          label: Text('Por mes'),
          style: ElevatedButton.styleFrom(
            backgroundColor: color.shade600,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),

        // Por fecha específica
        ElevatedButton.icon(
          onPressed: (isConnected == true && !isLoading)
              ? () => _showDatePickerDialog(context, type, onDate)
              : null,
          icon: const Icon(Icons.calendar_today),
          label: Text('Fecha específica'),
          style: ElevatedButton.styleFrom(
            backgroundColor: color.shade800,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  void _showYearPickerDialog(
      BuildContext context,
      String type,
      Function(int) onSelected,
      ) {
    final now = DateTime.now();
    showDialog(
      context: context,
      builder: (context) {
        int selectedYear = now.year;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Seleccionar año - $type'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('¿De qué año quieres copiar?'),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<int>(
                      isExpanded: true,
                      underline: const SizedBox(),
                      value: selectedYear,
                      onChanged: (value) => setState(() => selectedYear = value!),
                      items: List.generate(10, (index) {
                        final year = now.year - index;
                        return DropdownMenuItem(
                          value: year,
                          child: Text('$year'),
                        );
                      }),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onSelected(selectedYear);
                  },
                  child: const Text('Copiar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showMonthPickerDialog(
      BuildContext context,
      String type,
      Function(int, int) onSelected,
      ) {
    final now = DateTime.now();
    showDialog(
      context: context,
      builder: (context) {
        int selectedYear = now.year;
        int? selectedMonth;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Seleccionar mes - $type'),
              content: SizedBox(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Año:'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButton<int>(
                        isExpanded: true,
                        underline: const SizedBox(),
                        value: selectedYear,
                        onChanged: (value) => setState(() {
                          selectedYear = value!;
                          selectedMonth = null;
                        }),
                        items: List.generate(10, (index) {
                          final year = now.year - index;
                          return DropdownMenuItem(
                            value: year,
                            child: Text('$year'),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Mes:'),
                    const SizedBox(height: 8),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 2,
                      ),
                      itemCount: 12,
                      itemBuilder: (context, index) {
                        final month = index + 1;
                        final monthNames = [
                          'Ene',
                          'Feb',
                          'Mar',
                          'Abr',
                          'May',
                          'Jun',
                          'Jul',
                          'Ago',
                          'Sep',
                          'Oct',
                          'Nov',
                          'Dic'
                        ];
                        return InkWell(
                          onTap: () => setState(() => selectedMonth = month),
                          child: Container(
                            decoration: BoxDecoration(
                              color: selectedMonth == month
                                  ? Colors.green
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: selectedMonth == month
                                    ? Colors.green
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                monthNames[index],
                                style: TextStyle(
                                  color: selectedMonth == month
                                      ? Colors.white
                                      : Colors.black,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: selectedMonth != null
                      ? () {
                    Navigator.pop(context);
                    onSelected(selectedYear, selectedMonth!);
                  }
                      : null,
                  child: const Text('Copiar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDatePickerDialog(
      BuildContext context,
      String type,
      Function(DateTime) onSelected,
      ) {
    showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'),
    ).then((selectedDate) {
      if (selectedDate != null) {
        onSelected(selectedDate);
      }
    });
  }
}
