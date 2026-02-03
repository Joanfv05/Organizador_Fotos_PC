// test_paths.dart - Ejecuta esto primero
import 'dart:io';

void main() async {
  print('=== DEBUG DE RUTAS ===');

  // 1. Directorio ejecutable
  final executable = File(Platform.resolvedExecutable);
  print('1. Executable path: ${executable.path}');
  print('   Executable parent: ${executable.parent.path}');

  // 2. Directorio actual
  final currentDir = Directory.current;
  print('2. Current directory: ${currentDir.path}');

  // 3. Directorio home
  final homeDir = Platform.environment['HOME'];
  print('3. Home directory: $homeDir');

  // 4. Crear carpeta de prueba
  final testDir1 = Directory('${currentDir.path}/TEST_Fotos_2024');
  print('4. Intentando crear: ${testDir1.path}');

  try {
    await testDir1.create(recursive: true);
    print('   ✅ Carpeta creada exitosamente');

    // Crear archivo de prueba
    final testFile = File('${testDir1.path}/test.txt');
    await testFile.writeAsString('Test ${DateTime.now()}');
    print('   ✅ Archivo de prueba creado');

    // Listar contenido
    print('5. Contenido del directorio actual:');
    final files = await Directory(currentDir.path).list().toList();
    for (var file in files) {
      print('   - ${file.path}');
    }

  } catch (e) {
    print('   🔴 Error: $e');
  }
}