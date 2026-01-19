import 'package:flutter/material.dart';
import 'features/organizer/organizer_page.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const PhotoOrganizerApp());
}

class PhotoOrganizerApp extends StatelessWidget {
  const PhotoOrganizerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Photo Organizer PC',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const OrganizerPage(),
    );
  }
}
