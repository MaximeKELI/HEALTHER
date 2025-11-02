import 'package:flutter/services.dart';

/// Service pour le feedback haptique
class HapticFeedbackService {
  static final HapticFeedbackService _instance = HapticFeedbackService._internal();
  factory HapticFeedbackService() => _instance;
  HapticFeedbackService._internal();

  /// Vibration légère (succès)
  Future<void> lightImpact() async {
    await HapticFeedback.lightImpact();
  }

  /// Vibration moyenne (sélection)
  Future<void> mediumImpact() async {
    await HapticFeedback.mediumImpact();
  }

  /// Vibration forte (erreur)
  Future<void> heavyImpact() async {
    await HapticFeedback.heavyImpact();
  }

  /// Double vibration (attention)
  Future<void> doubleImpact() async {
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.mediumImpact();
  }

  /// Vibration très légère (navigation)
  Future<void> selectionClick() async {
    await HapticFeedback.selectionClick();
  }

  /// Feedback pour action réussie
  Future<void> success() async {
    await lightImpact();
  }

  /// Feedback pour action échouée
  Future<void> error() async {
    await doubleImpact();
  }

  /// Feedback pour action importante
  Future<void> important() async {
    await heavyImpact();
  }
}

