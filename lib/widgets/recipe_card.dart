import 'dart:io';

import 'package:flutter/material.dart';

import '../models/recipe_entry.dart';

/// Imagen de la receta (o un marcador si no tiene foto). Se usa tanto en la
/// lista como en el detalle para que la transición Hero sea idéntica.
class RecipeImage extends StatelessWidget {
  /// Crea la imagen de [recipe].
  const RecipeImage({super.key, required this.recipe, this.iconSize = 48});

  /// Receta cuya foto se muestra.
  final RecipeEntry recipe;

  /// Tamaño del ícono de marcador cuando no hay foto.
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      color: const Color(0xFF2A2A2A),
      alignment: Alignment.center,
      child: Icon(
        Icons.restaurant_menu,
        size: iconSize,
        color: Theme.of(context).colorScheme.primary,
      ),
    );

    if (recipe.imagePath.isEmpty) return placeholder;

    return Image.file(
      File(recipe.imagePath),
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, _, _) => placeholder,
    );
  }
}

/// Tarjeta reutilizable de la lista. La imagen va envuelta en un [Hero] cuyo
/// tag (`recipe-hero-<id>`) coincide con el de la pantalla de detalle.
///
/// **SRP:** solo presenta datos; las acciones se delegan en [onTap] y
/// [onFavoriteTap].
class RecipeCard extends StatelessWidget {
  /// Crea la tarjeta de [recipe].
  const RecipeCard({
    super.key,
    required this.recipe,
    required this.onTap,
    this.onFavoriteTap,
  });

  /// Receta que se muestra.
  final RecipeEntry recipe;

  /// Acción al tocar la tarjeta (normalmente abrir el detalle).
  final VoidCallback onTap;

  /// Acción del botón de corazón; `null` lo deshabilita.
  final VoidCallback? onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: recipe.heroTag,
                    child: RecipeImage(recipe: recipe),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: Colors.black54,
                      shape: const CircleBorder(),
                      child: IconButton(
                        tooltip: recipe.favorite
                            ? 'Quitar de favoritas'
                            : 'Marcar como favorita',
                        icon: Icon(
                          recipe.favorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: theme.colorScheme.primary,
                        ),
                        onPressed: onFavoriteTap,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _InfoChip(
                        icon: Icons.category_outlined,
                        label: recipe.category,
                      ),
                      _InfoChip(
                        icon: Icons.timer_outlined,
                        label: recipe.prepTime,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ícono + texto pequeño (categoría, tiempo).
class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
