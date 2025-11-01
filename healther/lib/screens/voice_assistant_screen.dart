import '../services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/voice_assistant_service.dart';

/// Écran de l'assistant vocal IA
class VoiceAssistantScreen extends StatefulWidget {
  const VoiceAssistantScreen({super.key});

  @override
  State<VoiceAssistantScreen> createState() => _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends State<VoiceAssistantScreen> {
  final VoiceAssistantService _voiceService = VoiceAssistantService();
  final List<String> _conversation = [];

  @override
  void initState() {
    super.initState();
    _voiceService.onSpeechResult = (text) {
      setState(() {
        _conversation.add('Vous: $text');
      });
      _handleVoiceCommand(text);
    };

    _voiceService.onSpeechError = (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $error')),
      );
    };

    // Salutation initiale
    _voiceService.speak(
      'Bonjour ! Je suis votre assistant vocal HEALTHER. Dites "statistiques" pour entendre les stats, ou "diagnostic" pour créer un nouveau diagnostic.',
    );
  }

  Future<void> _handleVoiceCommand(String command) async {
    final lowerCommand = command.toLowerCase();

    if (lowerCommand.contains('statistiques') || lowerCommand.contains('stats')) {
      try {
        final apiService = ApiService();
        final stats = await apiService.getStats();
        await _voiceService.speakStats(stats);
        setState(() {
          _conversation.add('Assistant: Statistiques lues à voix haute');
        });
      } catch (e) {
        await _voiceService.speak('Désolé, je ne peux pas charger les statistiques pour le moment.');
      }
    } else if (lowerCommand.contains('diagnostic') || lowerCommand.contains('nouveau')) {
      await _voiceService.speak('Pour créer un diagnostic, veuillez utiliser l\'écran de diagnostic.');
      setState(() {
        _conversation.add('Assistant: Redirection vers diagnostic');
      });
      // TODO: Naviguer vers l'écran de diagnostic
    } else if (lowerCommand.contains('bonjour') || lowerCommand.contains('salut')) {
      await _voiceService.speak('Bonjour ! Comment puis-je vous aider aujourd\'hui ?');
      setState(() {
        _conversation.add('Assistant: Salutation');
      });
    } else {
      await _voiceService.speak('Désolé, je n\'ai pas compris. Essayez "statistiques" ou "diagnostic".');
      setState(() {
        _conversation.add('Assistant: Commande non reconnue');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assistant Vocal IA'),
      ),
      body: Column(
        children: [
          // Conversation
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _conversation.length,
              itemBuilder: (context, index) {
                final message = _conversation[index];
                final isUser = message.startsWith('Vous:');
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue.shade50 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      message,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                );
              },
            ),
          ),

          // Contrôles vocaux
          Consumer<VoiceAssistantService>(
            builder: (context, voiceService, _) {
              return Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Bouton principal d'écoute
                    GestureDetector(
                      onTap: () async {
                        if (voiceService.isListening) {
                          await voiceService.stopListening();
                        } else {
                          final available = await voiceService.checkAvailability();
                          if (available) {
                            await voiceService.startListening();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Reconnaissance vocale non disponible',
                                ),
                              ),
                            );
                          }
                        }
                      },
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: voiceService.isListening
                              ? Colors.red
                              : Theme.of(context).primaryColor,
                          boxShadow: [
                            BoxShadow(
                              color: (voiceService.isListening
                                      ? Colors.red
                                      : Theme.of(context).primaryColor)
                                  .withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Icon(
                          voiceService.isListening
                              ? Icons.stop
                              : Icons.mic,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      voiceService.isListening
                          ? 'Écoute en cours... Parlez maintenant'
                          : voiceService.isSpeaking
                              ? 'En train de parler...'
                              : 'Appuyez pour parler',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: voiceService.isListening
                            ? Colors.red
                            : Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (voiceService.lastRecognizedText != null)
                      Text(
                        'Dernière commande: ${voiceService.lastRecognizedText}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

