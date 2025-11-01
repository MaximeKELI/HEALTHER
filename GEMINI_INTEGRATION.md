# 🤖 Intégration Gemini AI Voice - HEALTHER

Documentation pour l'intégration de l'API Google Gemini AI pour l'assistant vocal.

---

## 🔑 Configuration

### API Key

L'API key Gemini a été configurée :
```
AIzaSyDTTD9CZG7YZv8qhZlBMp3ok4qrDtmSKCE
```

**Stockage** :
- Backend : `backend/services/gemini_voice_service.js` (ligne 11)
- Environnement : Variable `GEMINI_API_KEY` dans `.env` (prioritaire)

⚠️ **Sécurité** : Pour la production, déplacer la clé dans `.env` uniquement.

---

## 📁 Fichiers Créés

### Backend

1. **`backend/services/gemini_voice_service.js`**
   - Service principal pour l'intégration Gemini
   - Méthodes :
     - `transcribeAudio()` - Transcription audio → texte
     - `chatWithContext()` - Chat conversationnel avec contexte HEALTHER
     - `generateAudioResponse()` - Génération texte → audio (TTS côté client pour l'instant)
     - `analyzeDiagnosticDescription()` - Analyse de descriptions vocales de diagnostics

2. **`backend/routes/voice_assistant.js`**
   - Routes API pour l'assistant vocal :
     - `POST /api/voice-assistant/transcribe` - Transcription audio
     - `POST /api/voice-assistant/chat` - Chat conversationnel
     - `POST /api/voice-assistant/speak` - Génération audio (TTS côté client)
     - `POST /api/voice-assistant/analyze-diagnostic` - Analyse de diagnostic

3. **`backend/server.js`**
   - Route ajoutée : `/api/voice-assistant`

### Frontend

1. **`lib/services/voice_assistant_service.dart`**
   - Méthodes ajoutées :
     - `transcribeAudio()` - Transcription via Gemini
     - `chatWithGemini()` - Chat conversationnel
     - `generateGeminiAudioResponse()` - Génération audio
     - `analyzeDiagnosticDescription()` - Analyse de diagnostic

2. **`lib/screens/voice_assistant_screen.dart`**
   - Écran mis à jour pour utiliser Gemini
   - Chat conversationnel avec contexte

---

## 🔌 Endpoints API

### 1. Transcription Audio
```http
POST /api/voice-assistant/transcribe
Content-Type: multipart/form-data
Authorization: Bearer <token>

Body:
  - audio: File (audio/wav, audio/pcm, etc.)

Response:
{
  "text": "Texte transcrit",
  "success": true
}
```

### 2. Chat Conversationnel
```http
POST /api/voice-assistant/chat
Content-Type: application/json
Authorization: Bearer <token>

Body:
{
  "message": "Bonjour",
  "conversationHistory": [
    {"role": "user", "text": "Message précédent"},
    {"role": "assistant", "text": "Réponse précédente"}
  ]
}

Response:
{
  "text": "Réponse de Gemini",
  "audioBase64": null,
  "success": true
}
```

### 3. Génération Audio (TTS côté client)
```http
POST /api/voice-assistant/speak
Content-Type: application/json
Authorization: Bearer <token>

Body:
{
  "text": "Texte à lire",
  "context": "Contexte optionnel"
}

Response:
{
  "text": "Texte à lire",
  "audioBase64": null,
  "mimeType": null,
  "success": true
}
```

### 4. Analyse de Diagnostic
```http
POST /api/voice-assistant/analyze-diagnostic
Content-Type: application/json
Authorization: Bearer <token>

Body:
{
  "description": "Description vocale du diagnostic"
}

Response:
{
  "maladie": "paludisme|typhoide|autre",
  "confidence": 0.0-1.0,
  "suggestions": ["suggestion1", "suggestion2"],
  "success": true
}
```

---

## 📝 Utilisation

### Dans Flutter

```dart
// Chat conversationnel
final voiceService = VoiceAssistantService();
final response = await voiceService.chatWithGemini(
  'Bonjour, quelles sont les statistiques ?',
  conversationHistory: [
    {'role': 'user', 'text': 'Message précédent'},
  ],
);

print(response['text']); // Réponse de Gemini
```

### Transcription Audio

```dart
// Enregistrer l'audio puis transcrire
final audioBytes = await recordAudio(); // Votre méthode d'enregistrement
final transcript = await voiceService.transcribeAudio(
  audioBytes,
  'audio/wav',
);
```

---

## ⚠️ Limitations Actuelles

1. **Audio Natif Gemini** : L'API native-audio nécessite une connexion WebSocket live, non implémentée pour l'instant. On utilise TTS standard côté client.

2. **Modèle** : Utilisation de `gemini-pro` (modèle standard). Le modèle `gemini-2.5-flash-native-audio-preview` nécessiterait l'API live.

3. **TTS** : Utilisation de `flutter_tts` pour la synthèse vocale (fallback sur TTS système).

---

## 🚀 Améliorations Futures

1. **API Live Gemini** : Implémenter l'API live avec WebSocket pour l'audio natif
2. **Support Multilingue Avancé** : Ajouter plus de langues (anglais, langues locales)
3. **Transcription en Temps Réel** : Streaming de la transcription
4. **Analyse Audio Médical** : Détection de motifs vocaux pour diagnostics

---

## ✅ Statut

- ✅ API Key configurée
- ✅ Service backend créé
- ✅ Routes API créées
- ✅ Service Flutter mis à jour
- ✅ Intégration dans l'écran assistant vocal
- ⚠️ Audio natif Gemini : En attente d'implémentation API live

---

**Note** : L'API key est actuellement hardcodée dans le service. Pour la production, déplacer dans `.env` uniquement.

