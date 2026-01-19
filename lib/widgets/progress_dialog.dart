import 'package:flutter/material.dart';

class ProgressDialog extends StatelessWidget {
  final String title;
  final String? message;

  const ProgressDialog({super.key, required this.title, this.message});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Función helper para mostrar el diálogo
  static Future<void> show(BuildContext context,
      {required String title, String? message}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ProgressDialog(title: title, message: message),
    );
  }

  /// Función helper para cerrar el diálogo
  static void hide(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }
}
