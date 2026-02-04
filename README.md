# 📱 Photo Organizer PC

Organiza tus fotos de Android en tu PC con Flutter. Simple, rápido y eficiente.

## 🚀 ¿Qué hace esta app?

* 🔌 **Detecta automáticamente** tu Android conectado por USB
* 📁 **Organiza fotos y videos** de forma inteligente
* 🖥️ **Interfaz moderna** para Windows y Linux
* ⚡ **Transferencia rápida** sin complicaciones
* 📱 **Monitoriza tu móvil** con scrcpy desde la app (Linux y Windows)

---

## 📦 Instalación Rápida

### 1. Clonar y ejecutar la app

```bash
git clone https://github.com/Joanfv05/Organizador_Fotos_PC.git
cd photo_organizer_pc
flutter pub get
flutter run
```

### 2. Estructura de binarios

Los binarios de **ADB y scrcpy** no están en assets, sino en:

```
external/adb/
├── linux/
│   ├── adb
│   ├── scrcpy
│   └── otros archivos
└── windows/
    ├── adb.exe
    ├── scrcpy.exe
    └── otros archivos
```

* Windows usa directamente los binarios de `external/adb/windows/`
* Linux usa los binarios de `external/adb/linux/`

---

### 3. Permisos en Linux (muy importante)

Linux **requiere permisos de ejecución** y acceso a USB para que `adb` y `scrcpy` funcionen:

```bash
cd ~/Escritorio/Organizador_Fotos_PC/external/adb/linux
chmod +x adb scrcpy

# Si hay problemas con USB:
sudo usermod -aG plugdev $USER
```

Luego cierra sesión y vuelve a entrar.

Después de esto, la app podrá iniciar `adb` y `scrcpy` automáticamente sin errores.

---

### 4. Instalar ADB y scrcpy opcionales (si quieres usar los binarios del sistema)

```bash
sudo apt update && sudo apt install android-tools-adb scrcpy
adb version
scrcpy --version
```

> ⚠️ Nota: la app detectará automáticamente `adb` y `scrcpy` del sistema si existen, pero **los binarios incluidos en `external/adb/` siguen siendo los recomendados**.

---

## 🔧 Primeros Pasos

### Paso 1: Activar depuración USB en tu Android

1. Ve a **Ajustes > Acerca del teléfono**
2. Toca **"Número de compilación" 7 veces** (activa "Opciones de desarrollador")
3. Ve a **Opciones de desarrollador > Depuración USB** y ACTÍVALO

### Paso 2: Conectar y usar

1. **Conecta tu Android** por USB
2. **Acepta "Permitir depuración USB"** en el teléfono
3. **¡Listo!** La app detectará tu dispositivo automáticamente

---

## 🐛 Problemas Comunes

### ❌ "No detecta mi Android"

```bash
adb kill-server && adb start-server
sudo adb devices  # Problema de permisos
```

### ❌ "scrcpy no muestra pantalla en Linux"

* Verifica que los binarios `adb` y `scrcpy` tengan permisos de ejecución en `external/adb/linux/`
* La app lanza scrcpy mediante shell (`runInShell: true`) para abrir la ventana de monitorización del móvil

> ⚠️ **Nota importante:** Linux requiere permisos correctos para ejecutar `adb start-server`. No es posible automatizar completamente estos permisos desde la app por seguridad del sistema. Debes ejecutarlos manualmente al menos una vez.

---

## 🗂️ Estructura Simple

```
lib/
├── core/adb/           ← Gestiona conexión Android y scrcpy
├── features/           ← Pantallas principales
├── widgets/            ← Botones y componentes
└── main.dart           ← Entrada principal
```

---

## 📱 Compatibilidad

| Sistema | Binarios incluidos      | Notas                                                                    |
| ------- | ----------------------- | ------------------------------------------------------------------------ |
| Windows | ✅ external/adb/windows/ | Funciona directamente desde ahí                                          |
| Linux   | ⚠️ external/adb/linux/  | Debes dar permisos y añadir usuario a plugdev antes de usar scrcpy y adb |

---

## ⚡ Características Técnicas

* ✅ **Detección automática** de ADB y scrcpy (sistema o `external/adb/`)
* ✅ **Manejo de errores** robusto
* ✅ **UI responsiva** con Material Design 3
* ✅ **Código limpio** y mantenible

---

## 🤝 Contribuir

1. **Haz fork** del repo
2. **Crea una rama** (`feature/nueva-funcionalidad`)
3. **Envía PR** con tus cambios
4. **¡Gracias!** 🎉

---

## 📄 Licencia

MIT - ¡Usa, modifica, comparte libremente!

---

💡 **Tips:**

* Usa cables USB de calidad para mejor velocidad
* Mantén ADB y scrcpy actualizados
* La primera conexión puede pedir permisos en el teléfono

✨ **¡Organiza y monitoriza tus recuerdos en segundos!**

---
