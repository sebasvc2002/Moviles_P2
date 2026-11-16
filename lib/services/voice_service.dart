/// Gadget 2 – Audio: dictado (speech_to_text) y lectura en voz alta
/// (flutter_tts).
///
/// **ISP:** el formulario solo necesita dictar y el detalle solo necesita
/// leer, así que cada uno depende de una interfaz pequeña ([SpeechInput] o
/// [SpeechOutput]). [VoiceService] implementa ambas, como pide el plan.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Contrato de entrada de audio: convertir voz en texto.
abstract interface class SpeechInput {
  /// Valida el permiso de micrófono y la disponibilidad del motor.
  ///
  /// Devuelve `false` (sin lanzar) si el dictado no se puede usar.
  Future<bool> initSpeech();

  /// Comienza a escuchar. [onResult] recibe el texto reconocido (parcial y
  /// final) y [onDone] se invoca una sola vez cuando termina la sesión, ya
  /// sea por silencio, error o [stopListening].
  void startListening({
    required void Function(String) onResult,
    required VoidCallback onDone,
  });

  /// Detiene el dictado en curso.
  Future<void> stopListening();

  /// Libera los recursos del motor de reconocimiento.
  Future<void> dispose();
}

/// Contrato de salida de audio: leer texto en voz alta.
abstract interface class SpeechOutput {
  /// Lee [text] en voz alta. El Future se completa cuando termina de hablar
  /// o cuando se llama a [stop]. Lanza una [Exception] si falla el motor.
  Future<void> speak(String text);

  /// Interrumpe la lectura en curso.
  Future<void> stop();

  /// Libera los recursos del motor de voz.
  Future<void> dispose();
}

/// Implementación de [SpeechInput] y [SpeechOutput] con speech_to_text y
/// flutter_tts.
class VoiceService implements SpeechInput, SpeechOutput {
  /// Crea el servicio; los motores se inicializan de forma perezosa.
  VoiceService();

  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _speechReady = false;
  bool _ttsReady = false;
  String? _localeId;
  VoidCallback? _onDone;

  // ---------------------------------------------------------------------------
  // Entrada de audio: dictado
  // ---------------------------------------------------------------------------

  @override
  Future<bool> initSpeech() async {
    if (_speechReady) return true;
    try {
      final mic = await Permission.microphone.request();
      if (!mic.isGranted) {
        debugPrint('[VoiceService] Permiso de micrófono denegado: $mic');
        return false;
      }

      _speechReady = await _speech.initialize(
        onStatus: _handleStatus,
        onError: _handleError,
      );
      if (_speechReady) {
        _localeId = await _resolveLocale();
      }
      return _speechReady;
    } catch (e) {
      debugPrint('[VoiceService] Error al iniciar el reconocimiento: $e');
      _speechReady = false;
      return false;
    }
  }

  /// Prefiere es_MX, luego es_ES, luego cualquier variante de español y por
  /// último el idioma del sistema.
  Future<String?> _resolveLocale() async {
    try {
      final locales = await _speech.locales();
      final ids = locales.map((l) => l.localeId.replaceAll('-', '_')).toList();
      for (final wanted in ['es_MX', 'es_ES']) {
        final i = ids.indexWhere(
          (id) => id.toLowerCase() == wanted.toLowerCase(),
        );
        if (i != -1) return locales[i].localeId;
      }
      final anySpanish = ids.indexWhere(
        (id) => id.toLowerCase().startsWith('es'),
      );
      if (anySpanish != -1) return locales[anySpanish].localeId;
      return (await _speech.systemLocale())?.localeId;
    } catch (e) {
      debugPrint('[VoiceService] No se pudieron obtener los idiomas: $e');
      return 'es_MX';
    }
  }

  @override
  void startListening({
    required void Function(String) onResult,
    required VoidCallback onDone,
  }) {
    if (!_speechReady) {
      onDone();
      return;
    }
    _onDone = onDone;
    _speech
        .listen(
          onResult: (result) => onResult(result.recognizedWords),
          listenOptions: SpeechListenOptions(
            localeId: _localeId,
            listenFor: const Duration(seconds: 60),
            pauseFor: const Duration(seconds: 4),
            partialResults: true,
            cancelOnError: true,
            listenMode: ListenMode.dictation,
          ),
        )
        .catchError((Object e) {
          debugPrint('[VoiceService] Error al escuchar: $e');
          _finish();
        });
  }

  @override
  Future<void> stopListening() async {
    try {
      await _speech.stop();
    } catch (e) {
      debugPrint('[VoiceService] Error al detener el dictado: $e');
    } finally {
      _finish();
    }
  }

  void _handleStatus(String status) {
    if (status == SpeechToText.doneStatus ||
        status == SpeechToText.notListeningStatus) {
      _finish();
    }
  }

  void _handleError(SpeechRecognitionError error) {
    debugPrint('[VoiceService] Error de reconocimiento: ${error.errorMsg}');
    _finish();
  }

  /// Invoca `onDone` una sola vez aunque lleguen varios eventos de cierre.
  void _finish() {
    final cb = _onDone;
    _onDone = null;
    cb?.call();
  }

  // ---------------------------------------------------------------------------
  // Salida de audio: lectura en voz alta
  // ---------------------------------------------------------------------------

  /// Configura el motor TTS (es-MX, velocidad 0.5, tono 1.0) la primera vez.
  Future<void> _initTts() async {
    if (_ttsReady) return;
    try {
      await _tts.setLanguage('es-MX');
      await _tts.setSpeechRate(0.5);
      await _tts.setPitch(1.0);
      await _tts.awaitSpeakCompletion(true);
      _ttsReady = true;
    } catch (e) {
      debugPrint('[VoiceService] Error al configurar TTS: $e');
    }
  }

  @override
  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    try {
      await _initTts();
      await _tts.speak(text);
    } catch (e) {
      debugPrint('[VoiceService] Error al reproducir audio: $e');
      throw Exception('No se pudo reproducir el audio: $e');
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (e) {
      debugPrint('[VoiceService] Error al detener el audio: $e');
    }
  }

  @override
  Future<void> dispose() async {
    _onDone = null;
    await stop();
    try {
      await _speech.cancel();
    } catch (e) {
      debugPrint('[VoiceService] Error al cancelar el dictado: $e');
    }
  }
}
