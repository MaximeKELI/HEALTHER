import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../services/biometric_auth_service.dart';

/// Écran pour l'authentification biométrique
class BiometricAuthScreen extends StatefulWidget {
  const BiometricAuthScreen({super.key});

  @override
  State<BiometricAuthScreen> createState() => _BiometricAuthScreenState();
}

class _BiometricAuthScreenState extends State<BiometricAuthScreen> {
  final BiometricAuthService _biometricAuth = BiometricAuthService();
  bool _isAvailable = false;
  List<BiometricType> _availableTypes = [];
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    _checkAvailability();
  }

  Future<void> _checkAvailability() async {
    final available = await _biometricAuth.isAvailable();
    final types = await _biometricAuth.getAvailableBiometrics();
    
    setState(() {
      _isAvailable = available;
      _availableTypes = types;
    });
  }

  Future<void> _authenticate() async {
    setState(() {
      _isAuthenticating = true;
    });

    try {
      final authenticated = await _biometricAuth.authenticate(
        localizedReason: 'Authentifiez-vous pour accéder à HEALTHER',
      );

      if (!mounted) return;

      if (authenticated) {
        // Authentification réussie - naviguer vers la route racine
        // AuthWrapper vérifiera l'authentification et affichera HomeScreen
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/',
          (route) => false, // Retire toutes les routes précédentes
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Authentification annulée'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur authentification: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isAuthenticating = false;
      });
    }
  }

  String _getBiometricTypeName(BiometricType type) {
    switch (type) {
      case BiometricType.face:
        return 'Face ID';
      case BiometricType.fingerprint:
        return 'Empreinte digitale';
      case BiometricType.iris:
        return 'Iris';
      case BiometricType.strong:
        return 'Authentification forte';
      case BiometricType.weak:
        return 'Authentification faible';
    }
  }

  IconData _getBiometricIcon(BiometricType type) {
    switch (type) {
      case BiometricType.face:
        return Icons.face;
      case BiometricType.fingerprint:
        return Icons.fingerprint;
      case BiometricType.iris:
        return Icons.remove_red_eye;
      default:
        return Icons.security;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Authentification Biométrique'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fingerprint,
              size: 100,
              color: _isAvailable ? Colors.green : Colors.grey,
            ),
            const SizedBox(height: 30),
            Text(
              _isAvailable
                  ? 'Authentification biométrique disponible'
                  : 'Authentification biométrique non disponible',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (_availableTypes.isNotEmpty) ...[
              const Text(
                'Types disponibles:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ..._availableTypes.map((type) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_getBiometricIcon(type)),
                        const SizedBox(width: 10),
                        Text(_getBiometricTypeName(type)),
                      ],
                    ),
                  )),
              const SizedBox(height: 30),
            ],
            if (_isAvailable)
              ElevatedButton.icon(
                onPressed: _isAuthenticating ? null : _authenticate,
                icon: _isAuthenticating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.fingerprint),
                label: Text(_isAuthenticating
                    ? 'Authentification...'
                    : 'S\'authentifier'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                ),
              )
            else
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Votre appareil ne supporte pas l\'authentification biométrique ou elle n\'est pas configurée.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

