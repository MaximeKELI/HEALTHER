import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccessibilityService {
  static final AccessibilityService _instance = AccessibilityService._internal();
  factory AccessibilityService() => _instance;
  AccessibilityService._internal();

  static const String _fontSizeKey = 'accessibility_font_size';
  static const String _highContrastKey = 'accessibility_high_contrast';
  static const String _hapticEnabledKey = 'accessibility_haptic_enabled';
  
  double _fontSize = 1.0;
  bool _highContrast = false;
  bool _hapticEnabled = true;

  double get fontSize => _fontSize;
  bool get highContrast => _highContrast;
  bool get hapticEnabled => _hapticEnabled;

  /// Charger les préférences d'accessibilité
  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _fontSize = prefs.getDouble(_fontSizeKey) ?? 1.0;
    _highContrast = prefs.getBool(_highContrastKey) ?? false;
    _hapticEnabled = prefs.getBool(_hapticEnabledKey) ?? true;
  }

  /// Changer la taille de police
  Future<void> setFontSize(double multiplier) async {
    _fontSize = multiplier.clamp(0.8, 2.0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontSizeKey, _fontSize);
  }

  /// Activer/désactiver le contraste élevé
  Future<void> setHighContrast(bool enabled) async {
    _highContrast = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_highContrastKey, enabled);
  }

  /// Activer/désactiver le retour haptique
  Future<void> setHapticEnabled(bool enabled) async {
    _hapticEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hapticEnabledKey, enabled);
  }

  /// Obtenir le thème avec contraste élevé
  ThemeData getTheme(ThemeData baseTheme) {
    if (!_highContrast) {
      return baseTheme;
    }

    return baseTheme.copyWith(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: Colors.white,
        secondary: Colors.cyan,
        surface: Colors.black,
        background: Colors.black,
        error: Colors.red,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: Colors.white,
        onBackground: Colors.white,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: Colors.black,
      cardColor: Colors.grey[900],
    );
  }
}
