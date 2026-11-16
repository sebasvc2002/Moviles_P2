# CookBook: recetario interactivo

Aplicación móvil desarrollada con Flutter para crear, guardar, organizar y
consultar recetas. Incluye almacenamiento local, captura de imágenes,
dictado por voz, lectura de instrucciones y registro opcional de la ubicación.

## Funcionalidades

- Crear y editar recetas con ingredientes, instrucciones y datos adicionales.
- Guardar la información de forma persistente en una base de datos SQLite local.
- Añadir fotografías desde la cámara o la galería.
- Dictar ingredientes e instrucciones mediante reconocimiento de voz.
- Escuchar el contenido de una receta mediante síntesis de voz.
- Guardar metadatos de ubicación asociados a las recetas.
- Consultar las recetas desde una interfaz adaptada a dispositivos móviles.

## Requisitos

- [Flutter](https://docs.flutter.dev/get-started/install) compatible con el
  SDK de Dart `3.13.4` o posterior dentro de la versión indicada en
  `pubspec.yaml`.
- Un dispositivo físico o un emulador configurado para Android, iOS, macOS,
  Linux, Windows o web, según la plataforma que se quiera ejecutar.

## Instalación

1. Clona este repositorio y entra en su directorio:

   ```bash
   git clone <URL_DEL_REPOSITORIO>
   cd m02_proyecto1
   ```

2. Instala las dependencias:

   ```bash
   flutter pub get
   ```

3. Comprueba los dispositivos disponibles:

   ```bash
   flutter devices
   ```

4. Ejecuta la aplicación:

   ```bash
   flutter run
   ```

## Pruebas y análisis

Para ejecutar las pruebas automatizadas:

```bash
flutter test
```

Para analizar el código:

```bash
flutter analyze
```

## Estructura principal

```text
lib/
├── database/     # Acceso y operaciones sobre SQLite
├── models/       # Modelos de datos de las recetas
├── screens/      # Pantallas principales de la aplicación
├── services/     # Cámara, voz, ubicación y otros servicios
└── widgets/      # Componentes visuales reutilizables
```

## Permisos

Las funciones de cámara, galería, micrófono, reconocimiento de voz y
ubicación requieren permisos del sistema operativo. Al utilizar estas
funciones, concede los permisos solicitados por la aplicación. La
configuración específica de Android e iOS se encuentra en sus respectivos
directorios nativos.

## Dependencias principales

- `sqflite` y `path_provider` para el almacenamiento local.
- `image_picker` para seleccionar o capturar imágenes.
- `speech_to_text` para el dictado.
- `flutter_tts` para la lectura de recetas.
- `permission_handler` para gestionar permisos.
- `geolocator` para obtener la ubicación.

## Licencia

Este proyecto es académico y no declara actualmente una licencia de
distribución.
