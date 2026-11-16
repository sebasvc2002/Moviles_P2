/// Implementación SQLite (sqflite) de [RecipeRepository].
///
/// **SRP:** su única responsabilidad es traducir operaciones de recetas a
/// consultas sobre la tabla `recipes`. No conoce la UI ni los servicios de
/// hardware.
library;

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/recipe_entry.dart';
import 'recipe_repository.dart';

/// Acceso Singleton a la base de datos local `cookbook.db`.
///
/// Cada operación está envuelta en try-catch: el error se registra en consola
/// y se relanza como una [Exception] controlada para que la UI lo muestre sin
/// cerrar la aplicación.
class DatabaseHelper implements RecipeRepository {
  DatabaseHelper._internal();

  /// Instancia única compartida por toda la app.
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static const String _dbName = 'cookbook.db';
  static const int _dbVersion = 1;

  /// Nombre de la tabla de recetas.
  static const String tableRecipes = 'recipes';

  Database? _database;

  /// Conexión abierta de forma perezosa la primera vez que se necesita.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, _dbName);
      return await openDatabase(path, version: _dbVersion, onCreate: _onCreate);
    } catch (e) {
      debugPrint('[DatabaseHelper] Error al abrir la base de datos: $e');
      throw Exception('Error al acceder a la base de datos: $e');
    }
  }

  /// Crea el esquema de la versión 1.
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableRecipes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        prepTime TEXT NOT NULL,
        ingredients TEXT NOT NULL,
        instructions TEXT NOT NULL,
        imagePath TEXT NOT NULL,
        latitude REAL,
        longitude REAL,
        isFavorite INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  @override
  Future<int> insertRecipe(RecipeEntry recipe) async {
    try {
      final db = await database;
      // El id lo asigna SQLite (AUTOINCREMENT).
      final map = recipe.toMap()..remove('id');
      return await db.insert(tableRecipes, map);
    } catch (e) {
      debugPrint('[DatabaseHelper] insertRecipe falló: $e');
      throw Exception('Error al acceder a la base de datos: $e');
    }
  }

  @override
  Future<List<RecipeEntry>> getAllRecipes() async {
    try {
      final db = await database;
      final rows = await db.query(tableRecipes, orderBy: 'createdAt DESC');
      return rows.map(RecipeEntry.fromMap).toList();
    } catch (e) {
      debugPrint('[DatabaseHelper] getAllRecipes falló: $e');
      throw Exception('Error al acceder a la base de datos: $e');
    }
  }

  @override
  Future<List<RecipeEntry>> getRecipesByCategory(String category) async {
    try {
      final db = await database;
      final rows = await db.query(
        tableRecipes,
        where: 'category = ?',
        whereArgs: [category],
        orderBy: 'createdAt DESC',
      );
      return rows.map(RecipeEntry.fromMap).toList();
    } catch (e) {
      debugPrint('[DatabaseHelper] getRecipesByCategory falló: $e');
      throw Exception('Error al acceder a la base de datos: $e');
    }
  }

  @override
  Future<List<RecipeEntry>> getFavoriteRecipes() async {
    try {
      final db = await database;
      final rows = await db.query(
        tableRecipes,
        where: 'isFavorite = ?',
        whereArgs: [1],
        orderBy: 'createdAt DESC',
      );
      return rows.map(RecipeEntry.fromMap).toList();
    } catch (e) {
      debugPrint('[DatabaseHelper] getFavoriteRecipes falló: $e');
      throw Exception('Error al acceder a la base de datos: $e');
    }
  }

  @override
  Future<int> toggleFavorite(int id, int currentValue) async {
    try {
      final db = await database;
      final newValue = currentValue == 1 ? 0 : 1;
      await db.update(
        tableRecipes,
        {'isFavorite': newValue},
        where: 'id = ?',
        whereArgs: [id],
      );
      return newValue;
    } catch (e) {
      debugPrint('[DatabaseHelper] toggleFavorite falló: $e');
      throw Exception('Error al acceder a la base de datos: $e');
    }
  }

  @override
  Future<int> deleteRecipe(int id) async {
    try {
      final db = await database;
      return await db.delete(tableRecipes, where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      debugPrint('[DatabaseHelper] deleteRecipe falló: $e');
      throw Exception('Error al acceder a la base de datos: $e');
    }
  }
}
