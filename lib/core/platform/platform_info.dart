import 'dart:io';

class PlatformInfo {
  static String get name {
    if (Platform.isLinux) return "Linux";
    if (Platform.isWindows) return "Windows";
    return "Desconocida";
  }
}
