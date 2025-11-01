const axios = require('axios');

/**
 * Service pour l'intégration de Google Gemini AI (Audio natif)
 * Utilise l'API Gemini REST pour la reconnaissance vocale et la génération de réponse
 * API Key fournie : AIzaSyDTTD9CZG7YZv8qhZlBMp3ok4qrDtmSKCE
 */
class GeminiVoiceService {
  constructor() {
    // Utiliser la clé API fournie ou celle de l'environnement
    this.apiKey = process.env.GEMINI_API_KEY || 'AIzaSyDTTD9CZG7YZv8qhZlBMp3ok4qrDtmSKCE';
    this.baseUrl = 'https://generativelanguage.googleapis.com/v1beta';
    // Utiliser le modèle standard Gemini pour l'instant (le modèle native-audio nécessite une API spéciale)
    this.model = 'gemini-pro';
  }

  /**
   * Transcrire un audio en texte (speech-to-text)
   * @param {Buffer|string} audioData - Données audio en base64 ou buffer
   * @param {string} mimeType - Type MIME de l'audio (audio/pcm;rate=16000, audio/wav, etc.)
   * @returns {Promise<string>} Texte transcrit
   */
  async transcribeAudio(audioData, mimeType = 'audio/pcm;rate=16000') {
    try {
      // Convertir en base64 si nécessaire
      const base64Audio = Buffer.isBuffer(audioData)
        ? audioData.toString('base64')
        : audioData;

      // Utiliser l'API Gemini pour analyser l'audio
      const response = await axios.post(
        `${this.baseUrl}/models/${this.model}:generateContent?key=${this.apiKey}`,
        {
          contents: [
            {
              parts: [
                {
                  inlineData: {
                    data: base64Audio,
                    mimeType: mimeType,
                  },
                },
                {
                  text: 'Transcris cet audio en texte français. Si c\'est une commande ou une question, réponds uniquement avec le texte transcrit.',
                },
              ],
            },
          ],
        },
        {
          headers: {
            'Content-Type': 'application/json',
          },
        }
      );

      const text = response.data?.candidates?.[0]?.content?.parts?.[0]?.text || '';
      return text.trim();
    } catch (error) {
      console.error('Erreur transcription Gemini:', error.response?.data || error.message);
      throw new Error(`Erreur transcription: ${error.message}`);
    }
  }

  /**
   * Générer une réponse audio (text-to-speech avec contexte)
   * @param {string} text - Texte à convertir en audio
   * @param {string} context - Contexte de la conversation (optionnel)
   * @returns {Promise<Buffer>} Données audio générées
   */
  async generateAudioResponse(text, context = null) {
    try {
      const systemInstruction = context
        ? `Tu es un assistant vocal pour HEALTHER, une application de diagnostic médical. ${context}`
        : 'Tu es un assistant vocal pour HEALTHER, une application de diagnostic médical. Réponds de manière amicale et professionnelle.';

      // Pour l'instant, l'API REST standard ne supporte pas directement l'audio natif
      // On génère le texte et on utilise TTS côté client
      // L'audio natif nécessite l'API live avec WebSocket
      const response = await axios.post(
        `${this.baseUrl}/models/${this.model}:generateContent?key=${this.apiKey}`,
        {
          contents: [
            {
              parts: [
                {
                  text: text,
                },
              ],
            },
          ],
          generationConfig: {
            temperature: 0.7,
          },
          systemInstruction: {
            parts: [
              {
                text: systemInstruction,
              },
            ],
          },
        },
        {
          headers: {
            'Content-Type': 'application/json',
          },
        }
      );

      // Pour l'audio natif Gemini, il faudrait implémenter l'API live avec WebSocket
      // Pour l'instant, on utilise TTS côté client avec le texte
      // Retourner null pour indiquer qu'on utilise TTS standard
      return null;
    } catch (error) {
      console.error('Erreur génération audio Gemini:', error.response?.data || error.message);
      throw new Error(`Erreur génération audio: ${error.message}`);
    }
  }

  /**
   * Chat conversationnel avec contexte HEALTHER
   * @param {string} userMessage - Message de l'utilisateur
   * @param {Array} conversationHistory - Historique de la conversation
   * @returns {Promise<{text: string, audio?: Buffer}>} Réponse texte et optionnellement audio
   */
  async chatWithContext(userMessage, conversationHistory = []) {
    try {
      const systemInstruction = `Tu es un assistant vocal pour HEALTHER, une application de diagnostic médical au Togo.
Tu peux aider les utilisateurs avec :
- Statistiques des diagnostics (paludisme, typhoïde)
- Navigation dans l'application
- Informations sur les diagnostics
- Conseils médicaux généraux
Réponds toujours en français, de manière claire et professionnelle.`;

      const contents = [
        {
          role: 'user',
          parts: [{ text: systemInstruction }],
        },
      ];

      // Ajouter l'historique
      conversationHistory.forEach((msg) => {
        contents.push({
          role: msg.role || 'user',
          parts: [{ text: msg.text }],
        });
      });

      // Ajouter le message actuel
      contents.push({
        role: 'user',
        parts: [{ text: userMessage }],
      });

      const response = await axios.post(
        `${this.baseUrl}/models/${this.model}:generateContent?key=${this.apiKey}`,
        {
          contents: conversationHistory.map(msg => ({
            role: msg.role || 'user',
            parts: [{ text: msg.text }],
          })).concat([{
            role: 'user',
            parts: [{ text: userMessage }],
          }]),
          generationConfig: {
            temperature: 0.7,
            maxOutputTokens: 1000,
          },
          systemInstruction: {
            parts: [{ text: systemInstruction }],
          },
        },
        {
          headers: {
            'Content-Type': 'application/json',
          },
        }
      );

      const textResponse =
        response.data?.candidates?.[0]?.content?.parts?.[0]?.text || '';
      
      // L'audio sera généré côté client avec TTS standard
      // Pour l'audio natif Gemini, il faudrait implémenter l'API live

      return {
        text: textResponse.trim(),
        audio: null, // TTS côté client
      };
    } catch (error) {
      console.error('Erreur chat Gemini:', error.response?.data || error.message);
      throw new Error(`Erreur chat: ${error.message}`);
    }
  }

  /**
   * Analyser un diagnostic vocal
   * @param {string} description - Description vocale du diagnostic
   * @returns {Promise<{maladie: string, confidence: number, suggestions: Array}>}
   */
  async analyzeDiagnosticDescription(description) {
    try {
      const prompt = `Tu es un expert médical. Analyse cette description de symptômes et suggère le type de maladie probable (paludisme, typhoïde, ou autre).
Description: ${description}

Réponds au format JSON:
{
  "maladie": "paludisme|typhoide|autre",
  "confidence": 0.0-1.0,
  "suggestions": ["suggestion1", "suggestion2"]
}`;

      const response = await axios.post(
        `${this.baseUrl}/models/${this.model}:generateContent?key=${this.apiKey}`,
        {
          contents: [
            {
              parts: [{ text: prompt }],
            },
          ],
          generationConfig: {
            responseMimeType: 'application/json',
            temperature: 0.3,
          },
        },
        {
          headers: {
            'Content-Type': 'application/json',
          },
        }
      );

      const jsonResponse =
        response.data?.candidates?.[0]?.content?.parts?.[0]?.text || '{}';
      return JSON.parse(jsonResponse);
    } catch (error) {
      console.error('Erreur analyse diagnostic:', error.response?.data || error.message);
      throw new Error(`Erreur analyse: ${error.message}`);
    }
  }
}

module.exports = new GeminiVoiceService();

