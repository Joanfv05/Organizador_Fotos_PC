````markdown
# 📱 Photo Organizer PC

Organiza tus fotos de Android en tu PC con Flutter. Simple, rápido y eficiente.

## 🚀 ¿Qué hace esta app?

- 🔌 **Detecta automáticamente** tu Android conectado por USB
- 📁 **Organiza fotos y videos** de forma inteligente
- 🖥️ **Interfaz moderna** para Windows y Linux
- ⚡ **Transferencia rápida** sin complicaciones
- 📱 **Monitoriza tu móvil** con scrcpy desde la app (Linux y Windows)

## 📦 Instalación Rápida

### 1. Instalar ADB (Linux/macOS)
```bash
# Linux (Ubuntu/Debian):
sudo apt update && sudo apt install android-tools-adb

# Verificar que funciona:
adb version
````

### 2. Instalar scrcpy (solo Linux)

```bash
# Linux (Ubuntu/Debian):
sudo apt update && sudo apt install scrcpy

# Verifica que funciona:
scrcpy
```

> ⚠️ **Nota:** En Windows, scrcpy ya viene incluido en los assets de la app.

### 3. Clonar y ejecutar la app

```bash
git clone https://github.com/tuusuario/photo_organizer_pc.git
cd photo_organizer_pc
flutter pub get
flutter run
```

## 🔧 Primeros Pasos

### Paso 1: Activar depuración USB en tu Android

1. Ve a **Ajustes > Acerca del teléfono**
2. Toca **"Número de compilación" 7 veces** (activa "Opciones de desarrollador")
3. Ve a **Opciones de desarrollador > Depuración USB** y ACTÍVALO

### Paso 2: Conectar y usar

1. **Conecta tu Android** por USB
2. **Acepta "Permitir depuración USB"** en el teléfono
3. **¡Listo!** La app detectará tu dispositivo automáticamente

### Paso 3: Monitorizar móvil con scrcpy

* En Linux: asegúrate de que `scrcpy` esté instalado (`sudo apt install scrcpy`)
* Pulsa el botón **Iniciar scrcpy** en la app para abrir la ventana de monitorización
* En Windows: el botón usa la versión incluida en los assets de la app

## 🐛 Problemas Comunes

### ❌ "No detecta mi Android"

```bash
# Soluciones rápidas:
adb kill-server && adb start-server
sudo adb devices  # Problema de permisos

# Permisos en Linux:
sudo usermod -aG plugdev $USER
```

### ❌ "scrcpy no muestra pantalla en Linux"

* Asegúrate de tener instalado scrcpy en el sistema: `sudo apt install scrcpy`
* Ejecuta `scrcpy` en terminal para probar que funcione
* La app lanza scrcpy mediante shell (`runInShell: true`) para abrir la ventana

### ❌ "Error de Flutter al iniciar"

**Causa:** Acceso a `Theme.of(context)` demasiado pronto
**Solución:** Ya está corregido en el código. Si lo ves, no uses `const` en `MaterialApp(home:)`

## 🗂️ Estructura Simple

```
lib/
├── core/adb/           ← Gestiona conexión Android y scrcpy
├── features/           ← Pantallas principales
├── widgets/            ← Botones y componentes
└── main.dart           ← Entrada principal
```

## 🛠️ Para Desarrolladores

### ¿Cómo funciona la detección ADB y scrcpy?

```dart
final adb = ADBService(); // Auto-detecta ADB del sistema o usa assets
bool conectado = await adb.isDeviceConnected();

// Scrcpy (Linux usa scrcpy del sistema, Windows de assets)
await _startScrcpy();
```

### Build para producción

```bash
# Windows:
flutter build windows

# Linux:
flutter build linux

# Los ejecutables estarán en:
# build/windows/runner/Release/
# build/linux/runner/release/
```

## 📱 Compatibilidad

| Sistema | ADB Requerido | Scrcpy      | Notas                                        |
| ------- | ------------- | ----------- | -------------------------------------------- |
| Windows | ✅ Incluido    | ✅ Incluido  | Descarga automática en assets                |
| Linux   | ⚠️ Instalar   | ⚠️ Instalar | `sudo apt install android-tools-adb scrcpy`  |
| macOS   | ⚠️ Instalar   | ⚠️ Instalar | `brew install android-platform-tools scrcpy` |

## ⚡ Características Técnicas

* ✅ **Detección automática** de ADB y scrcpy (sistema o assets)
* ✅ **Manejo de errores** robusto
* ✅ **UI responsiva** con Material Design 3
* ✅ **Código limpio** y mantenible

## 🤝 Contribuir

1. **Haz fork** del repo
2. **Crea una rama** (`feature/nueva-funcionalidad`)
3. **Envía PR** con tus cambios
4. **¡Gracias!** 🎉

## 📄 Licencia

MIT - ¡Usa, modifica, comparte libremente!

---

💡 **Tips:**

* Usa cables USB de calidad para mejor velocidad
* Mantén ADB y scrcpy actualizados
* La primera conexión puede pedir permisos en el teléfono

✨ **¡Organiza y monitoriza tus recuerdos en segundos!**

```
