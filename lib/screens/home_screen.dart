/// Pantalla principal (ruta `/`): lista de recetas con filtros.
///
/// **SRP:** la pantalla solo dibuja estados y navega; cada filtro sabe cómo
/// consultarse y qué mensaje mostrar cuando no hay resultados.
library;

import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../database/recipe_repository.dart';
import '../models/recipe_entry.dart';
import '../widgets/recipe_card.dart';

/// Filtro del Drawer.
///
/// **OCP:** cada variante encapsula su consulta ([load]) y sus textos, así
/// que agregar un filtro nuevo no obliga a modificar la pantalla.
sealed class _RecipeFilter {
  const _RecipeFilter();

  /// Texto del AppBar y del elemento del Drawer.
  String get title;

  /// Mensaje principal cuando la consulta no devuelve recetas.
  String get emptyTitle;

  /// Mensaje secundario cuando la consulta no devuelve recetas.
  String get emptySubtitle;

  /// Indica si el estado vacío debe ofrecer el botón "Crear receta".
  bool get offersCreate => true;

  /// Ícono del estado vacío.
  IconData get emptyIcon => Icons.soup_kitchen_outlined;

  /// Ejecuta la consulta correspondiente sobre [repository].
  Future<List<RecipeEntry>> load(RecipeRepository repository);
}

/// Todas las recetas.
final class _AllFilter extends _RecipeFilter {
  const _AllFilter();

  @override
  String get title => 'Todas las recetas';
  @override
  String get emptyTitle => 'Tu recetario está vacío';
  @override
  String get emptySubtitle => '¡Crea tu primera receta y empieza a cocinar!';
  @override
  Future<List<RecipeEntry>> load(RecipeRepository repository) =>
      repository.getAllRecipes();

  @override
  bool operator ==(Object other) => other is _AllFilter;
  @override
  int get hashCode => (_AllFilter).hashCode;
}

/// Solo las recetas favoritas.
final class _FavoritesFilter extends _RecipeFilter {
  const _FavoritesFilter();

  @override
  String get title => 'Mis Favoritas';
  @override
  String get emptyTitle => 'Aún no tienes recetas favoritas';
  @override
  String get emptySubtitle =>
      'Marca una receta con el corazón para verla aquí.';
  @override
  bool get offersCreate => false;
  @override
  IconData get emptyIcon => Icons.favorite_border;
  @override
  Future<List<RecipeEntry>> load(RecipeRepository repository) =>
      repository.getFavoriteRecipes();

  @override
  bool operator ==(Object other) => other is _FavoritesFilter;
  @override
  int get hashCode => (_FavoritesFilter).hashCode;
}

/// Recetas de una categoría concreta.
final class _CategoryFilter extends _RecipeFilter {
  const _CategoryFilter(this.category);

  /// Categoría filtrada, una de [kRecipeCategories].
  final String category;

  @override
  String get title => category;
  @override
  String get emptyTitle => 'No hay recetas en "$category"';
  @override
  String get emptySubtitle =>
      'Crea una receta de esta categoría o elige otro filtro.';
  @override
  Future<List<RecipeEntry>> load(RecipeRepository repository) =>
      repository.getRecipesByCategory(category);

  @override
  bool operator ==(Object other) =>
      other is _CategoryFilter && other.category == category;
  @override
  int get hashCode => category.hashCode;
}

/// Lista de recetas cargada con `FutureBuilder`, con Drawer de filtros y
/// botón para crear recetas.
///
/// **DIP:** depende de [RecipeRepository]; si no se inyecta usa
/// [DatabaseHelper.instance].
class HomeScreen extends StatefulWidget {
  /// Crea la pantalla. [repository] permite sustituir la base de datos real
  /// (por ejemplo, en pruebas).
  const HomeScreen({super.key, this.repository});

  /// Repositorio de recetas; por defecto [DatabaseHelper.instance].
  final RecipeRepository? repository;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final RecipeRepository _db =
      widget.repository ?? DatabaseHelper.instance;

  _RecipeFilter _filter = const _AllFilter();
  late Future<List<RecipeEntry>> _recipesFuture;

  @override
  void initState() {
    super.initState();
    _recipesFuture = _loadRecipes();
  }

  Future<List<RecipeEntry>> _loadRecipes() => _filter.load(_db);

  /// Vuelve a ejecutar la consulta del filtro activo.
  void _reload() {
    setState(() {
      _recipesFuture = _loadRecipes();
    });
  }

  /// Cierra el Drawer y aplica [filter] si es distinto del actual.
  void _applyFilter(_RecipeFilter filter) {
    Navigator.pop(context); // Cierra el Drawer.
    if (filter == _filter) return;
    _filter = filter;
    _reload();
  }

  /// Abre el formulario y recarga la lista si se guardó una receta.
  Future<void> _openCreate() async {
    final created = await Navigator.pushNamed(context, '/create');
    if (!mounted) return;
    if (created == true) _reload();
  }

  /// Abre el detalle de [recipe] y recarga la lista al volver.
  Future<void> _openDetail(RecipeEntry recipe) async {
    await Navigator.pushNamed(context, '/detail', arguments: recipe);
    if (!mounted) return;
    // El detalle puede cambiar el favorito o eliminar la receta.
    _reload();
  }

  /// Invierte el favorito de [recipe] desde la tarjeta de la lista.
  Future<void> _toggleFavorite(RecipeEntry recipe) async {
    final id = recipe.id;
    if (id == null) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _db.toggleFavorite(id, recipe.isFavorite);
      if (!mounted) return;
      _reload();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_filter.title)),
      drawer: _buildDrawer(context),
      body: RefreshIndicator(
        onRefresh: () async {
          _reload();
          await _recipesFuture.catchError((_) => <RecipeEntry>[]);
        },
        child: FutureBuilder<List<RecipeEntry>>(
          future: _recipesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _ErrorView(
                message: snapshot.error.toString(),
                onRetry: _reload,
              );
            }
            final recipes = snapshot.data ?? const <RecipeEntry>[];
            if (recipes.isEmpty) {
              return _EmptyView(filter: _filter, onCreate: _openCreate);
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: recipes.length,
              separatorBuilder: (_, _) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final recipe = recipes[index];
                return RecipeCard(
                  key: ValueKey(recipe.id),
                  recipe: recipe,
                  onTap: () => _openDetail(recipe),
                  onFavoriteTap: () => _toggleFavorite(recipe),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        icon: const Icon(Icons.add),
        label: const Text('Nueva receta'),
      ),
    );
  }

  /// Drawer con un elemento por filtro; resalta el filtro activo.
  Widget _buildDrawer(BuildContext context) {
    final theme = Theme.of(context);

    Widget tile(IconData icon, _RecipeFilter filter) {
      return ListTile(
        leading: Icon(icon),
        title: Text(filter.title),
        selected: filter == _filter,
        selectedColor: theme.colorScheme.primary,
        onTap: () => _applyFilter(filter),
      );
    }

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF1E1E1E)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.menu_book,
                  size: 48,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 8),
                Text(
                  'CookBook',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Tu recetario interactivo',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          tile(Icons.restaurant, const _AllFilter()),
          tile(Icons.favorite, const _FavoritesFilter()),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text('Categorías', style: theme.textTheme.labelLarge),
          ),
          tile(Icons.free_breakfast, const _CategoryFilter('Desayuno')),
          tile(Icons.dinner_dining, const _CategoryFilter('Plato Fuerte')),
          tile(Icons.cake, const _CategoryFilter('Postre')),
          tile(Icons.local_bar, const _CategoryFilter('Bebida')),
        ],
      ),
    );
  }
}

/// Tarjeta de error con el mensaje capturado y botón "Reintentar".
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 48),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(
                  Icons.error_outline,
                  size: 56,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 12),
                Text('Algo salió mal', style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Estado vacío: ícono y mensajes que define el filtro activo.
class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.filter, required this.onCreate});

  final _RecipeFilter filter;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 64),
        Icon(filter.emptyIcon, size: 96, color: theme.colorScheme.primary),
        const SizedBox(height: 16),
        Text(
          filter.emptyTitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(filter.emptySubtitle, textAlign: TextAlign.center),
        if (filter.offersCreate) ...[
          const SizedBox(height: 24),
          Center(
            child: FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('Crear receta'),
            ),
          ),
        ],
      ],
    );
  }
}
