// adb_config.dart
// NO MODIFICAR MANUALMENTE

import 'dart:io';

class ADBConfig {
  // Rutas relativas para ADB
  static const String windowsAdbPath = r'external\adb\windows\adb.exe';
  static const String linuxAdbPath = r'external/adb/linux/adb';
  
  // Ruta para releases (junto al ejecutable)
  static String get releaseAdbPath {
    if (Platform.isWindows) {
      return r'adb\windows\adb.exe';
    } else {
      return r'adb/linux/adb';
    }
  }
}
