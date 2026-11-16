/// Gadget 1 – Multimedia: cámara, galería y almacenamiento de imágenes.
///
/// **DIP:** la UI depende de [ImageStorage]; [MediaService] es la
/// implementación concreta con image_picker y path_provider.
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Contrato para obtener y descartar fotos de recetas.
abstract interface class ImageStorage {
  /// Abre la cámara o la galería según [source] y guarda la foto elegida de
  /// forma permanente.
  ///
  /// Devuelve la ruta absoluta del archivo guardado, o `null` si el usuario
  /// canceló. Lanza [PermissionDeniedException] si falta el permiso, o una
  /// [Exception] con un mensaje legible ante cualquier otro error.
  Future<String?> pickAndSaveImage(ImageSource source);

  /// Borra la imagen en [path] si existe. Nunca lanza excepciones.
  Future<void> deleteImage(String path);
}

/// Implementación de [ImageStorage] con image_picker.
///
/// Copia la imagen a ApplicationDocumentsDirectory porque la ruta temporal
/// del picker puede ser eliminada por el sistema operativo.
class MediaService implements ImageStorage {
  /// Crea el servicio. [picker] permite inyectar un `ImagePicker` alternativo.
  MediaService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<String?> pickAndSaveImage(ImageSource source) async {
    try {
      await _ensurePermission(source);

      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (picked == null) return null;

      final docsDir = await getApplicationDocumentsDirectory();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedPath = p.join(docsDir.path, fileName);

      await File(picked.path).copy(savedPath);
      return savedPath;
    } on PermissionDeniedException {
      rethrow;
    } catch (e) {
      debugPrint('[MediaService] Error al obtener la imagen: $e');
      throw Exception('No se pudo obtener la imagen: $e');
    }
  }

  /// Solicita el permiso correspondiente. La cámara es obligatoria; para la
  /// galería el selector del sistema (Photo Picker / PHPicker) funciona sin
  /// permiso, así que solo se bloquea si el usuario lo negó permanentemente.
  Future<void> _ensurePermission(ImageSource source) async {
    final permission = source == ImageSource.camera
        ? Permission.camera
        : Permission.photos;
    final status = await permission.request();

    if (status.isPermanentlyDenied) {
      throw PermissionDeniedException(
        source == ImageSource.camera
            ? 'Permiso de cámara denegado. Actívalo en Ajustes.'
            : 'Permiso de galería denegado. Actívalo en Ajustes.',
      );
    }
    if (source == ImageSource.camera && status.isDenied) {
      throw PermissionDeniedException('Se necesita permiso de cámara.');
    }
  }

  @override
  Future<void> deleteImage(String path) async {
    if (path.isEmpty) return;
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (e) {
      debugPrint('[MediaService] No se pudo eliminar $path: $e');
    }
  }
}

/// Error de permisos con un mensaje apto para mostrar al usuario.
class PermissionDeniedException implements Exception {
  /// Crea la excepción con el [message] que verá el usuario.
  PermissionDeniedException(this.message);

  /// Texto legible que explica qué permiso falta.
  final String message;

  @override
  String toString() => message;
}
