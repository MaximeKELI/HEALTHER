import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Service pour l'assistant IA vocal multilingue
class VoiceAssistantService with ChangeNotifier {
  static final VoiceAssistantService _instance = VoiceAssistantService._internal();
  factory VoiceAssistantService() => _instance;

  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _isListening = false;
  bool _isSpeaking = false;
  String _currentLanguage = 'fr-FR';
  String? _lastRecognizedText;
  List<String> _supportedLanguages = ['fr-FR', 'en-US'];

  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  String get currentLanguage => _currentLanguage;
  String? get lastRecognizedText => _lastRecognizedText;
  List<String> get supportedLanguages => _supportedLanguages;

  // Callback pour la reconnaissance vocale
  Function(String)? onSpeechResult;
  Function(String)? onSpeechError;

  void _init() {
    _initializeTTS();
  }

  VoiceAssistantService._internal() {
    _init();
  }

  Future<void> _initializeTTS() async {
    await _tts.setLanguage(_currentLanguage);
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    _tts.setCompletionHandler(() {
      _isSpeaking = false;
      notifyListeners();
    });

    _tts.setErrorHandler((msg) {
      _isSpeaking = false;
      notifyListeners();
    });
  }

  /// Parler un texte
  Future<void> speak(String text, {String? language}) async {
    try {
      if (language != null && language != _currentLanguage) {
        await _tts.setLanguage(language);
        _currentLanguage = language;
      }

      _isSpeaking = true;
      notifyListeners();

      await _tts.speak(text);
    } catch (e) {
      _isSpeaking = false;
      notifyListeners();
      print('Erreur TTS: $e');
    }
  }

  /// Arrêter de parler
  Future<void> stopSpeaking() async {
    await _tts.stop();
    _isSpeaking = false;
    notifyListeners();
  }

  /// Démarrer l'écoute vocale
  Future<bool> startListening({String? language}) async {
    if (_isListening) return false;

    final available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          _isListening = false;
          notifyListeners();
        }
      },
      onError: (error) {
        _isListening = false;
        notifyListeners();
        onSpeechError?.call(error.errorMsg);
      },
    );

    if (!available) {
      return false;
    }

    _isListening = true;
    notifyListeners();

    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          _lastRecognizedText = result.recognizedWords;
          _isListening = false;
          notifyListeners();
          onSpeechResult?.call(result.recognizedWords);
        }
      },
      localeId: language ?? _currentLanguage,
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
    );

    return true;
  }

  /// Arrêter l'écoute
  Future<void> stopListening() async {
    await _speech.stop();
    _isListening = false;
    notifyListeners();
  }

  /// Annuler l'écoute
  Future<void> cancelListening() async {
    await _speech.cancel();
    _isListening = false;
    notifyListeners();
  }

  /// Lire les statistiques à voix haute
  Future<void> speakStats(Map<String, dynamic> stats) async {
    final text = _formatStatsForSpeech(stats);
    await speak(text);
  }

  String _formatStatsForSpeech(Map<String, dynamic> stats) {
    final global = stats['global'] ?? {};
    final total = global['total'] ?? 0;
    final positifs = global['positifs'] ?? 0;
    final taux = global['taux_positivite'] ?? 0.0;

    return 'Statistiques globales: $total cas au total, dont $positifs cas positifs. '
           'Le taux de positivité est de ${taux.toStringAsFixed(1)} pourcent.';
  }

  /// Commandes vocales pour navigation
  Future<void> handleVoiceCommand(String command) async {
    final lowerCommand = command.toLowerCase();
    
    if (lowerCommand.contains('statistiques') || lowerCommand.contains('stats')) {
      // TODO: Naviguer vers dashboard
    } else if (lowerCommand.contains('diagnostic') || lowerCommand.contains('nouveau')) {
      // TODO: Naviguer vers diagnostic
    } else if (lowerCommand.contains('historique')) {
      // TODO: Naviguer vers historique
    } else if (lowerCommand.contains('notifications')) {
      // TODO: Naviguer vers notifications
    }
  }

  /// Vérifier si le speech-to-text est disponible
  Future<bool> checkAvailability() async {
    return await _speech.initialize();
  }

  /// Obtenir les langues disponibles
  Future<List<stt.LocaleName>> getAvailableLanguages() async {
    return await _speech.locales();
  }

  /// Changer la langue
  Future<void> setLanguage(String languageCode) async {
    _currentLanguage = languageCode;
    await _tts.setLanguage(languageCode);
    notifyListeners();
  }
}

