import 'package:shared_preferences/shared_preferences.dart';

/// Service pour gérer l'onboarding
class OnboardingService {
  static final OnboardingService _instance = OnboardingService._internal();
  factory OnboardingService() => _instance;
  OnboardingService._internal();

  static const String _onboardingCompletedKey = 'onboarding_completed';
  static const String _onboardingStepKey = 'onboarding_step';

  /// Vérifier si l'onboarding est terminé
  Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingCompletedKey) ?? false;
  }

  /// Marquer l'onboarding comme terminé
  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompletedKey, true);
  }

  /// Réinitialiser l'onboarding (pour tests)
  Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_onboardingCompletedKey);
    await prefs.remove(_onboardingStepKey);
  }

  /// Obtenir l'étape actuelle
  Future<int> getCurrentStep() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_onboardingStepKey) ?? 0;
  }

  /// Sauvegarder l'étape
  Future<void> saveStep(int step) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_onboardingStepKey, step);
  }
}

