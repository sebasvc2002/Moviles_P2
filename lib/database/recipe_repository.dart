/// Contrato de persistencia de recetas.
///
/// **DIP / ISP:** las pantallas dependen de esta abstracción y no de SQLite.
/// Así se puede sustituir la implementación (por ejemplo, un repositorio en
/// memoria para pruebas) sin modificar la UI.
library;

import '../models/recipe_entry.dart';

/// Operaciones de lectura y escritura sobre las recetas guardadas.
///
/// Toda implementación debe lanzar una [Exception] con un mensaje legible si
/// la operación falla, para que la UI pueda mostrarlo sin cerrar la app.
abstract interface class RecipeRepository {
  /// Guarda [recipe] (su `id` se ignora) y devuelve el id asignado.
  Future<int> insertRecipe(RecipeEntry recipe);

  /// Devuelve todas las recetas, de la más reciente a la más antigua.
  Future<List<RecipeEntry>> getAllRecipes();

  /// Devuelve las recetas de [category], de la más reciente a la más antigua.
  Future<List<RecipeEntry>> getRecipesByCategory(String category);

  /// Devuelve solo las recetas marcadas como favoritas.
  Future<List<RecipeEntry>> getFavoriteRecipes();

  /// Invierte el favorito de la receta [id] a partir de [currentValue]
  /// (0 o 1) y devuelve el nuevo valor.
  Future<int> toggleFavorite(int id, int currentValue);

  /// Elimina la receta [id] y devuelve el número de filas borradas.
  Future<int> deleteRecipe(int id);
}
