```markdown
# 📱 Photo Organizer PC

Organiza tus fotos de Android en tu PC con Flutter. Simple, rápido y eficiente.

## 🚀 ¿Qué hace esta app?

- 🔌 **Detecta automáticamente** tu Android conectado por USB
- 📁 **Organiza fotos y videos** de forma inteligente
- 🖥️ **Interfaz moderna** para Windows y Linux
- ⚡ **Transferencia rápida** sin complicaciones

## 📦 Instalación Rápida

### 1. Instalar ADB (Linux/macOS)
```bash
# Linux (Ubuntu/Debian):
sudo apt update && sudo apt install android-tools-adb

# Verificar que funciona:
adb version
```

### 2. Clonar y ejecutar
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

## 🐛 Problemas Comunes

### ❌ "No detecta mi Android"
```bash
# Soluciones rápidas:
adb kill-server && adb start-server  # Reiniciar ADB
sudo adb devices  # Probable problema de permisos

# Permisos en Linux:
sudo usermod -aG plugdev $USER
```

### ❌ "Error de Flutter al iniciar"
**Causa:** Acceso a `Theme.of(context)` demasiado pronto  
**Solución:** Ya está corregido en el código. Si lo ves, no uses `const` en `MaterialApp(home:)`

## 🗂️ Estructura Simple

```
lib/
├── core/adb/           ← Gestiona conexión Android ← ¡IMPORTANTE!
├── features/           ← Pantallas principales
├── widgets/            ← Botones y componentes
└── main.dart           ← Entrada principal
```

## 🛠️ Para Desarrolladores

### ¿Cómo funciona la detección ADB?
```dart
// Auto-detecta ADB del sistema o usa el incluido
final adb = ADBService(); // ¡Sin configurar rutas!
bool conectado = await adb.isDeviceConnected();
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

| Sistema | ADB Requerido | Notas |
|---------|---------------|-------|
| Windows | ✅ Incluido | Descarga automática |
| Linux | ⚠️ Instalar | `sudo apt install android-tools-adb` |
| macOS | ⚠️ Instalar | `brew install android-platform-tools` |

## ⚡ Características Técnicas

- ✅ **Detección automática** de ADB (sistema o assets)
- ✅ **Manejo de errores** robusto
- ✅ **UI responsiva** con Material Design 3
- ✅ **Código limpio** y mantenible

## 🤝 Contribuir

1. **Haz fork** del repo
2. **Crea una rama** (`feature/nueva-funcionalidad`)
3. **Envía PR** con tus cambios
4. **¡Gracias!** 🎉

## 📄 Licencia

MIT - ¡Usa, modifica, comparte libremente!

---

💡 **Tips:**
- Usa cables USB de calidad para mejor velocidad
- Mantén ADB actualizado en Linux: `sudo apt upgrade android-tools-adb`
- La primera conexión puede pedir permisos en el teléfono

✨ **¡Organiza tus recuerdos en segundos!**
```

## ¿Por qué este README es efectivo?

✅ **Simple** - Instalación en 2 pasos  
✅ **Directo** - Va al grano sin rodeos  
✅ **Soluciona problemas** - Incluye los errores que YA resolvimos  
✅ **Técnico cuando es necesario** - Explica la parte de ADB claramente  
✅ **Amigable** - Con emojis y formato legible  

**Perfecto para:** usuarios que quieren funcionar rápido y desarrolladores que necesitan entender la estructura.