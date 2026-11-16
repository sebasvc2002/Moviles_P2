/// Lectura guiada de una receta, paso a paso.
///
/// **SRP:** decidir *qué* se lee y en qué orden es responsabilidad de esta
/// clase; *cómo* se reproduce el audio lo resuelve el [SpeechOutput] inyectado
/// (**DIP**). La pantalla de detalle solo inicia o detiene la narración.
library;

import '../models/recipe_entry.dart';
import 'voice_service.dart';

/// Narra una receta frase por frase y permite detenerla entre frases.
class RecipeNarrator {
  /// Crea un narrador que habla a través de [output].
  RecipeNarrator(this._output);

  final SpeechOutput _output;
  bool _cancelled = false;

  /// Guion que se lee para [recipe]: título, ingredientes y cada paso
  /// numerado.
  static List<String> scriptFor(RecipeEntry recipe) {
    final steps = recipe.instructionSteps;
    return [
      recipe.title,
      'Ingredientes: ${recipe.ingredientList.join(', ')}.',
      'Instrucciones.',
      for (var i = 0; i < steps.length; i++) 'Paso ${i + 1}. ${steps[i]}',
      '¡Buen provecho!',
    ];
  }

  /// Lee [recipe] completa. Se completa al terminar o tras [stop].
  ///
  /// Propaga la [Exception] del motor de voz si la reproducción falla.
  Future<void> narrate(RecipeEntry recipe) async {
    _cancelled = false;
    for (final segment in scriptFor(recipe)) {
      if (_cancelled) break;
      await _output.speak(segment);
    }
  }

  /// Interrumpe la frase actual y evita que se lean las siguientes.
  Future<void> stop() async {
    _cancelled = true;
    await _output.stop();
  }

  /// Detiene la narración y libera el motor de voz.
  Future<void> dispose() async {
    _cancelled = true;
    await _output.dispose();
  }
}
