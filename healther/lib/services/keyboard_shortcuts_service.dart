import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Service pour gérer les raccourcis clavier (Desktop)
class KeyboardShortcutsService {
  static final KeyboardShortcutsService _instance = KeyboardShortcutsService._internal();
  factory KeyboardShortcutsService() => _instance;
  KeyboardShortcutsService._internal();

  final Map<LogicalKeySet, VoidCallback> _shortcuts = {};
  final Map<String, String> _helpShortcuts = {};

  /// Enregistrer un raccourci
  void registerShortcut({
    required LogicalKeySet keys,
    required VoidCallback callback,
    String? description,
  }) {
    _shortcuts[keys] = callback;
    if (description != null) {
      _helpShortcuts[_getKeyDescription(keys)] = description;
    }
  }

  /// Gérer les raccourcis dans un widget
  Widget buildShortcuts({
    required Widget child,
    required BuildContext context,
  }) {
    return Shortcuts(
      shortcuts: _shortcuts.map(
        (key, callback) => MapEntry(key, VoidIntent(callback)),
      ),
      child: child,
    );
  }

  /// Obtenir la liste des raccourcis pour l'aide
  Map<String, String> getHelpShortcuts() {
    return Map.unmodifiable(_helpShortcuts);
  }

  String _getKeyDescription(LogicalKeySet keys) {
    final keyStrings = keys.keys.map((key) {
      if (key == LogicalKeyboardKey.control) return 'Ctrl';
      if (key == LogicalKeyboardKey.meta) return 'Cmd';
      if (key == LogicalKeyboardKey.alt) return 'Alt';
      if (key == LogicalKeyboardKey.shift) return 'Shift';
      return key.keyLabel;
    }).join(' + ');
    return keyStrings;
  }
}

/// Intent pour les raccourcis
class VoidIntent extends Intent {
  final VoidCallback callback;
  
  VoidIntent(this.callback);
}

