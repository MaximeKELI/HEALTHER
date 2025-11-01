import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// Service pour l'authentification biométrique (empreinte digitale, Face ID)
class BiometricAuthService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  /// Vérifier si l'authentification biométrique est disponible
  Future<bool> isAvailable() async {
    try {
      return await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();
    } catch (e) {
      print('Erreur vérification biométrie: $e');
      return false;
    }
  }

  /// Obtenir les types de biométrie disponibles
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      print('Erreur récupération biométrie: $e');
      return [];
    }
  }

  /// Authentifier avec biométrie
  Future<bool> authenticate({
    String? localizedReason,
    bool useErrorDialogs = true,
    bool stickyAuth = true,
  }) async {
    try {
      // Vérifier si disponible
      final available = await isAvailable();
      if (!available) {
        return false;
      }

      // Authentifier
      final authenticated = await _localAuth.authenticate(
        localizedReason: localizedReason ??
            'Veuillez vous authentifier pour accéder à HEALTHER',
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          biometricOnly: true, // Uniquement biométrie, pas de PIN
        ),
      );

      return authenticated;
    } on PlatformException catch (e) {
      print('Erreur authentification biométrique: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      print('Erreur authentification: $e');
      return false;
    }
  }

  /// Authentifier avec option PIN fallback
  Future<bool> authenticateWithFallback({
    String? localizedReason,
    bool useErrorDialogs = true,
    bool stickyAuth = true,
  }) async {
    try {
      final available = await isAvailable();
      if (!available) {
        return false;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: localizedReason ??
            'Veuillez vous authentifier pour accéder à HEALTHER',
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          biometricOnly: false, // Permettre PIN fallback
        ),
      );

      return authenticated;
    } catch (e) {
      print('Erreur authentification avec fallback: $e');
      return false;
    }
  }

  /// Arrêter l'authentification (si en cours)
  Future<void> stopAuthentication() async {
    try {
      await _localAuth.stopAuthentication();
    } catch (e) {
      print('Erreur arrêt authentification: $e');
    }
  }
}

