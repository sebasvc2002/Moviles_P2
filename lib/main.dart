/// Punto de entrada de CookBook.
///
/// **Raíz de composición (DIP):** aquí se declaran las rutas nombradas. Las
/// pantallas se crean sin argumentos y usan sus implementaciones de
/// producción por defecto; para pruebas se les pueden inyectar otras.
library;

import 'package:flutter/material.dart';

import 'screens/detail_screen.dart';
import 'screens/form_screen.dart';
import 'screens/home_screen.dart';

/// Arranca la aplicación.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CookBookApp());
}

/// Fondo carbón de la paleta culinaria oscura.
const Color kCharcoal = Color(0xFF121212);

/// Color de tarjetas y campos.
const Color kCardColor = Color(0xFF1E1E1E);

/// Acento naranja vibrante.
const Color kAccentOrange = Color(0xFFFF6B35);

/// Widget raíz: tema oscuro y mapa de rutas nombradas
/// (`/`, `/detail`, `/create`).
class CookBookApp extends StatelessWidget {
  /// Crea la aplicación.
  const CookBookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CookBook',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/detail': (context) => const DetailScreen(),
        '/create': (context) => const FormScreen(),
      },
    );
  }

  /// Construye el tema oscuro a partir de `ThemeData.dark()`.
  ThemeData _buildTheme() {
    final base = ThemeData.dark();
    final scheme = base.colorScheme.copyWith(
      primary: kAccentOrange,
      onPrimary: Colors.white,
      secondary: kAccentOrange,
      onSecondary: Colors.white,
      surface: kCardColor,
    );

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: kCharcoal,
      appBarTheme: const AppBarTheme(
        backgroundColor: kCharcoal,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: kCardColor,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      drawerTheme: const DrawerThemeData(backgroundColor: kCharcoal),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: kAccentOrange,
        foregroundColor: Colors.white,
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: kCardColor,
        side: BorderSide.none,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: kCardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kAccentOrange, width: 2),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
