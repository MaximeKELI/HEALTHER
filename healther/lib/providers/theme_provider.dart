import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider pour la gestion des thèmes (mode sombre, thèmes personnalisables)
class ThemeProvider with ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';
  static const String _themeColorKey = 'theme_color';

  ThemeMode _themeMode = ThemeMode.system;
  Color _primaryColor = Colors.blue;
  Color _secondaryColor = Colors.green;

  ThemeMode get themeMode => _themeMode;
  Color get primaryColor => _primaryColor;
  Color get secondaryColor => _secondaryColor;

  bool get isDarkMode {
    if (_themeMode == ThemeMode.dark) return true;
    if (_themeMode == ThemeMode.light) return false;
    // System mode - utiliser le thème système
    return false; // Par défaut, sera détecté par le système
  }

  ThemeProvider() {
    _loadThemePreferences();
  }

  Future<void> _loadThemePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final themeModeStr = prefs.getString(_themeModeKey);
      if (themeModeStr != null) {
        _themeMode = ThemeMode.values.firstWhere(
          (mode) => mode.toString() == themeModeStr,
          orElse: () => ThemeMode.system,
        );
      }

      final primaryColorInt = prefs.getInt(_themeColorKey);
      if (primaryColorInt != null) {
        _primaryColor = Color(primaryColorInt);
      }

      notifyListeners();
    } catch (e) {
      print('Erreur chargement préférences thème: $e');
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeModeKey, mode.toString());
    } catch (e) {
      print('Erreur sauvegarde mode thème: $e');
    }
  }

  Future<void> setPrimaryColor(Color color) async {
    _primaryColor = color;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeColorKey, color.value);
    } catch (e) {
      print('Erreur sauvegarde couleur: $e');
    }
  }

  Future<void> setThemeColors({Color? primary, Color? secondary}) async {
    if (primary != null) _primaryColor = primary;
    if (secondary != null) _secondaryColor = secondary;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      if (primary != null) {
        await prefs.setInt(_themeColorKey, primary.value);
      }
    } catch (e) {
      print('Erreur sauvegarde couleurs: $e');
    }
  }

  /// Obtenir un thème avec les couleurs personnalisées
  ThemeData getTheme(ThemeData baseTheme) {
    return baseTheme.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primaryColor,
        primary: _primaryColor,
        secondary: _secondaryColor,
        brightness: isDarkMode ? Brightness.dark : Brightness.light,
      ),
      useMaterial3: true,
    );
  }

  /// Thèmes prédéfinis
  static const List<ThemePreset> presets = [
    ThemePreset('Bleu', Colors.blue, Colors.green),
    ThemePreset('Vert', Colors.green, Colors.teal),
    ThemePreset('Orange', Colors.orange, Colors.deepOrange),
    ThemePreset('Violet', Colors.purple, Colors.deepPurple),
    ThemePreset('Rouge', Colors.red, Colors.pink),
  ];

  Future<void> applyPreset(ThemePreset preset) async {
    await setThemeColors(
      primary: preset.primaryColor,
      secondary: preset.secondaryColor,
    );
  }
}

/// Preset de thème
class ThemePreset {
  final String name;
  final Color primaryColor;
  final Color secondaryColor;

  const ThemePreset(this.name, this.primaryColor, this.secondaryColor);
}

