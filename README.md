# 📱 Photo Organizer PC

Organiza tus fotos de Android en tu PC con Flutter. Simple, rápido y eficiente.

## 🚀 ¿Qué hace esta app?

- 🔌 **Detecta automáticamente** tu Android conectado por USB
- 📁 **Organiza fotos y videos** de forma inteligente
- 🖥️ **Interfaz moderna** para Windows y Linux
- ⚡ **Transferencia rápida** sin complicaciones
- 📱 **Monitoriza tu móvil** con scrcpy desde la app (Linux y Windows)

## 📦 Instalación Rápida

### 1. Instalar ADB (Linux)
```bash
# Linux (Ubuntu/Debian):
sudo apt update && sudo apt install android-tools-adb

# Verificar que funciona:
adb version
````

### 2. Instalar scrcpy (solo Linux)

⚠️ La app busca el binario **scrcpy** en: `$HOME/scrcpy-linux-x86_64-v3.3.4/scrcpy`.  
Debes **descargar la versión oficial** desde [GitHub](https://github.com/Genymobile/scrcpy/releases/tag/v3.3.4) y extraerla **exactamente en esa ruta** para que la app pueda iniciarlo.

### Verifica que funciona:
$HOME/scrcpy-linux-x86_64-v3.3.4/scrcpy

> ⚠️ **Nota:** En Windows, scrcpy ya viene incluido en los assets de la app.

### 3. Clonar y ejecutar la app

```bash
git clone https://github.com/Joanfv05/Organizador_Fotos_PC.git
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
adb kill-server && adb start-server
sudo adb devices  # Problema de permisos

# Permisos en Linux:
sudo usermod -aG plugdev $USER
```

### ❌ "scrcpy no muestra pantalla en Linux"

* Asegúrate de **descargar scrcpy** desde [GitHub](https://github.com/Genymobile/scrcpy/releases/tag/v3.3.4) y extraerlo en: `$HOME/scrcpy-linux-x86_64-v3.3.4/`
* Verifica que el binario exista en: `$HOME/scrcpy-linux-x86_64-v3.3.4/scrcpy`
* La app lanza scrcpy mediante shell (`runInShell: true`) para abrir la ventana de monitorización del móvil

## 🗂️ Estructura Simple

```
lib/
├── core/adb/           ← Gestiona conexión Android y scrcpy
├── features/           ← Pantallas principales
├── widgets/            ← Botones y componentes
└── main.dart           ← Entrada principal
```

## 📱 Compatibilidad

| Sistema | ADB Requerido | Scrcpy      | Notas                                                                        |
| ------- | ------------- | ----------- | ---------------------------------------------------------------------------- |
| Windows | ✅ Incluido    | ✅ Incluido  | Descarga automática en assets                                                |
| Linux   | ⚠️ Instalar   | ⚠️ Instalar | Instalar scrcpy manualmente y ubicarlo en `$HOME/scrcpy-linux-x86_64-v3.3.4` |

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

