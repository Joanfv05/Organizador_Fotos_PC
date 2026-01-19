import 'dart:io';

class ADBService {
  /// Verifica si hay un dispositivo Android conectado
  Future<bool> isDeviceConnected() async {
    try {
      // Ejecuta `adb devices` en el PC
      final result = await Process.run('adb', ['devices']);
      if (result.exitCode != 0) return false;

      // La salida contiene "device" si hay un móvil conectado
      final output = result.stdout.toString();
      return output.contains('\tdevice');
    } catch (e) {
      return false;
    }
  }

  /// Lista archivos de una carpeta remota en el móvil
  Future<List<String>> listFiles(String remotePath) async {
    try {
      final result = await Process.run('adb', ['shell', 'ls', remotePath]);
      if (result.exitCode != 0) return [];

      final output = result.stdout.toString();
      final files = output.split('\n').where((f) => f.isNotEmpty).toList();
      return files;
    } catch (e) {
      return [];
    }
  }

  /// Copia un archivo del móvil al PC
  Future<bool> pullFile(String remotePath, String localPath) async {
    try {
      final result = await Process.run('adb', ['pull', remotePath, localPath]);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }
}
