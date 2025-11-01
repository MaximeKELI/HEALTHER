import 'dart:async';
import 'dart:convert';
import 'api_service.dart';
import 'package:http/http.dart' as http;
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

  /// Parler un texte (avec option Gemini audio natif)
  Future<void> speak(String text, {String? language, bool useGemini = false}) async {
    try {
      if (language != null && language != _currentLanguage) {
        await _tts.setLanguage(language);
        _currentLanguage = language;
      }

      _isSpeaking = true;
      notifyListeners();

      // Si Gemini est activé, essayer de générer l'audio natif d'abord
      if (useGemini) {
        try {
          final audioData = await generateGeminiAudioResponse(text);
          if (audioData != null) {
            // TODO: Jouer l'audio Gemini (nécessite un player audio)
            // Pour l'instant, fallback sur TTS standard
            await _tts.speak(text);
            _isSpeaking = false;
            notifyListeners();
            return;
          }
        } catch (e) {
          print('Erreur audio Gemini, fallback sur TTS: $e');
        }
      }

      // Fallback sur TTS standard
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
  Future<void> speakStats(Map<String, dynamic> stats, {bool useGemini = false}) async {
    final text = _formatStatsForSpeech(stats);
    await speak(text, useGemini: useGemini);
  }

  String _formatStatsForSpeech(Map<String, dynamic> stats) {
    final global = stats['global'] ?? {};
    final total = global['total'] ?? 0;
    final positifs = global['positifs'] ?? 0;
    final taux = global['taux_positivite'] ?? 0.0;

    return 'Statistiques globales: $total cas au total, dont $positifs cas positifs. '
           'Le taux de positivité est de ${taux.toStringAsFixed(1)} pourcent.';
  }

  /// Transcrire un fichier audio via l'API Gemini
  Future<String> transcribeAudio(List<int> audioBytes, String mimeType) async {
    try {
      final apiService = ApiService();
      final baseUrl = apiService.baseUrl.replaceAll('/api', '');
      final uri = Uri.parse('$baseUrl/api/voice-assistant/transcribe');

      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(apiService.headers);
      request.files.add(http.MultipartFile.fromBytes(
        'audio',
        audioBytes,
        filename: 'audio.wav',
        contentType: mimeType.contains('pcm')
            ? const {'Content-Type': 'audio/pcm'}
            : const {'Content-Type': 'audio/wav'},
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['text'] as String? ?? '';
      } else {
        throw Exception('Erreur transcription: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur transcription Gemini: $e');
      rethrow;
    }
  }

  /// Chat conversationnel avec Gemini
  Future<Map<String, dynamic>> chatWithGemini(
    String message, {
    List<Map<String, dynamic>>? conversationHistory,
  }) async {
    try {
      final apiService = ApiService();
      final baseUrl = apiService.baseUrl.replaceAll('/api', '');
      final uri = Uri.parse('$baseUrl/api/voice-assistant/chat');

      final response = await http.post(
        uri,
        headers: apiService.headers,
        body: json.encode({
          'message': message,
          'conversationHistory': conversationHistory ?? [],
        }),
      );

      if (response.statusCode >= 400) {
        throw Exception('Erreur chat: ${response.statusCode}');
      }

      final data = json.decode(response.body);
      return {
        'text': data['text'] as String? ?? '',
        'audioBase64': data['audioBase64'] as String?,
      };
    } catch (e) {
      print('Erreur chat Gemini: $e');
      rethrow;
    }
  }

  /// Générer une réponse audio via Gemini
  Future<List<int>?> generateGeminiAudioResponse(String text, {String? context}) async {
    try {
      final apiService = ApiService();
      final baseUrl = apiService.baseUrl.replaceAll('/api', '');
      final uri = Uri.parse('$baseUrl/api/voice-assistant/speak');

      final response = await http.post(
        uri,
        headers: apiService.headers,
        body: json.encode({
          'text': text,
          'context': context,
        }),
      );

      if (response.statusCode >= 400) {
        print('Erreur génération audio: ${response.statusCode}');
        return null;
      }

      final data = json.decode(response.body);
      final audioBase64 = data['audioBase64'] as String?;
      if (audioBase64 != null) {
        return base64Decode(audioBase64);
      }
      return null;
    } catch (e) {
      print('Erreur génération audio Gemini: $e');
      return null;
    }
  }

  /// Analyser une description vocale de diagnostic
  Future<Map<String, dynamic>> analyzeDiagnosticDescription(
    String description,
  ) async {
    try {
      final apiService = ApiService();
      final baseUrl = apiService.baseUrl.replaceAll('/api', '');
      final uri = Uri.parse('$baseUrl/api/voice-assistant/analyze-diagnostic');

      final response = await http.post(
        uri,
        headers: apiService.headers,
        body: json.encode({
          'description': description,
        }),
      );

      if (response.statusCode >= 400) {
        throw Exception('Erreur analyse: ${response.statusCode}');
      }

      return json.decode(response.body) as Map<String, dynamic>;
    } catch (e) {
      print('Erreur analyse diagnostic Gemini: $e');
      rethrow;
    }
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

