import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'features/organizer/presentation/views/organizer_page.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const PhotoOrganizerApp());
}

class PhotoOrganizerApp extends StatelessWidget {
  const PhotoOrganizerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Organizador de Fotos PC',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const OrganizerPage(),

      // Configuración de localización
      locale: const Locale('es', 'ES'),
      supportedLocales: const [
        Locale('es', 'ES'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}