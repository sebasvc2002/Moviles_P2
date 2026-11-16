/// Metadatos de ubicación para las recetas.
///
/// **DIP:** la UI depende de [LocationProvider] y recibe un [GeoPoint] propio,
/// sin conocer el tipo `Position` de geolocator.
library;

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Par de coordenadas GPS en grados decimales.
typedef GeoPoint = ({double latitude, double longitude});

/// Contrato para obtener la ubicación actual del dispositivo.
abstract interface class LocationProvider {
  /// Devuelve la ubicación actual, o `null` si no está disponible.
  ///
  /// Nunca lanza excepciones: la ubicación es opcional para guardar recetas.
  Future<GeoPoint?> getCurrentPosition();
}

/// Implementación de [LocationProvider] con geolocator.
///
/// Si el servicio está apagado, el permiso es denegado o hay un error/timeout,
/// devuelve `null` (o la última posición conocida) en lugar de fallar.
class LocationService implements LocationProvider {
  /// Tiempo máximo de espera por una lectura nueva del GPS.
  static const Duration timeLimit = Duration(seconds: 10);

  @override
  Future<GeoPoint?> getCurrentPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        debugPrint('[LocationService] Servicio de ubicación desactivado.');
        return null;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint('[LocationService] Permiso de ubicación denegado.');
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: timeLimit,
        ),
      );
      return _toGeoPoint(position);
    } catch (e) {
      debugPrint('[LocationService] Error al obtener ubicación: $e');
      // Respaldo: última posición conocida.
      try {
        return _toGeoPoint(await Geolocator.getLastKnownPosition());
      } catch (_) {
        return null;
      }
    }
  }

  GeoPoint? _toGeoPoint(Position? position) => position == null
      ? null
      : (latitude: position.latitude, longitude: position.longitude);
}
