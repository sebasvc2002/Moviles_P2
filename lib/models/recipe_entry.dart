/// Modelo de dominio de la app.
///
/// **SRP:** describe una receta y sabe convertirse a/desde un `Map` de SQLite
/// y separar su texto en líneas. No accede a la base de datos ni a la UI.
library;

/// Categorías disponibles para una receta.
///
/// **OCP:** añadir una categoría solo requiere agregarla aquí; el formulario
/// la toma de esta lista.
const List<String> kRecipeCategories = [
  'Desayuno',
  'Plato Fuerte',
  'Postre',
  'Bebida',
];

/// Representa una receta almacenada en la tabla `recipes` de SQLite.
///
/// Es inmutable: los cambios se hacen creando una copia con [copyWith].
class RecipeEntry {
  /// Id asignado por SQLite; `null` mientras la receta no se ha guardado.
  final int? id;

  /// Nombre del platillo.
  final String title;

  /// Una de las categorías de [kRecipeCategories].
  final String category;

  /// Tiempo de preparación en texto libre (por ejemplo, `"30 min"`).
  final String prepTime;

  /// Ingredientes, uno por línea.
  final String ingredients;

  /// Pasos de preparación, uno por línea.
  final String instructions;

  /// Ruta absoluta de la imagen dentro de ApplicationDocumentsDirectory.
  /// Cadena vacía si la receta no tiene foto.
  final String imagePath;

  /// Latitud donde se creó la receta; `null` si no se obtuvo ubicación.
  final double? latitude;

  /// Longitud donde se creó la receta; `null` si no se obtuvo ubicación.
  final double? longitude;

  /// 0 = no favorita, 1 = favorita.
  final int isFavorite;

  /// Fecha de creación en formato ISO-8601.
  final String createdAt;

  /// Crea una receta. [isFavorite] vale 0 (no favorita) por defecto.
  const RecipeEntry({
    this.id,
    required this.title,
    required this.category,
    required this.prepTime,
    required this.ingredients,
    required this.instructions,
    required this.imagePath,
    this.latitude,
    this.longitude,
    this.isFavorite = 0,
    required this.createdAt,
  });

  /// Indica si la receta está marcada como favorita.
  bool get favorite => isFavorite == 1;

  /// Indica si la receta tiene coordenadas GPS guardadas.
  bool get hasLocation => latitude != null && longitude != null;

  /// Tag único compartido entre la lista y el detalle para la animación Hero.
  String get heroTag => 'recipe-hero-$id';

  /// Ingredientes como lista, sin líneas vacías.
  List<String> get ingredientList => _splitLines(ingredients);

  /// Pasos de preparación como lista, sin líneas vacías.
  List<String> get instructionSteps => _splitLines(instructions);

  static List<String> _splitLines(String text) => text
      .split(RegExp(r'\r?\n'))
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();

  /// Convierte la receta en una fila de la tabla `recipes`.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'prepTime': prepTime,
      'ingredients': ingredients,
      'instructions': instructions,
      'imagePath': imagePath,
      'latitude': latitude,
      'longitude': longitude,
      'isFavorite': isFavorite,
      'createdAt': createdAt,
    };
  }

  /// Reconstruye una receta desde una fila de SQLite, con valores por
  /// defecto seguros si falta alguna columna.
  factory RecipeEntry.fromMap(Map<String, dynamic> map) {
    return RecipeEntry(
      id: map['id'] as int?,
      title: map['title'] as String? ?? '',
      category: map['category'] as String? ?? kRecipeCategories.first,
      prepTime: map['prepTime'] as String? ?? '',
      ingredients: map['ingredients'] as String? ?? '',
      instructions: map['instructions'] as String? ?? '',
      imagePath: map['imagePath'] as String? ?? '',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      isFavorite: map['isFavorite'] as int? ?? 0,
      createdAt:
          map['createdAt'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  /// Devuelve una copia con [id] y/o [isFavorite] reemplazados.
  RecipeEntry copyWith({int? id, int? isFavorite}) {
    return RecipeEntry(
      id: id ?? this.id,
      title: title,
      category: category,
      prepTime: prepTime,
      ingredients: ingredients,
      instructions: instructions,
      imagePath: imagePath,
      latitude: latitude,
      longitude: longitude,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt,
    );
  }
}
