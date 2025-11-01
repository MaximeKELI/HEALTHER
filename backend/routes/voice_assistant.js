const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const geminiVoiceService = require('../services/gemini_voice_service');
const multer = require('multer');

// Configuration multer pour upload audio
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB max
  },
  fileFilter: (req, file, cb) => {
    if (file.mimetype.startsWith('audio/')) {
      cb(null, true);
    } else {
      cb(new Error('Le fichier doit être un fichier audio'), false);
    }
  },
});

/**
 * Transcrire un fichier audio en texte
 * POST /api/voice-assistant/transcribe
 */
router.post(
  '/transcribe',
  authenticateToken,
  upload.single('audio'),
  async (req, res) => {
    try {
      if (!req.file) {
        return res.status(400).json({ error: 'Fichier audio requis' });
      }

      const audioBuffer = req.file.buffer;
      const mimeType = req.file.mimetype || 'audio/pcm;rate=16000';

      const transcript = await geminiVoiceService.transcribeAudio(
        audioBuffer,
        mimeType
      );

      res.json({
        text: transcript,
        success: true,
      });
    } catch (error) {
      console.error('Erreur transcription:', error);
      res.status(500).json({
        error: 'Erreur lors de la transcription',
        message: error.message,
      });
    }
  }
);

/**
 * Chat conversationnel avec contexte HEALTHER
 * POST /api/voice-assistant/chat
 */
router.post('/chat', authenticateToken, async (req, res) => {
  try {
    const { message, conversationHistory } = req.body;

    if (!message) {
      return res.status(400).json({ error: 'Message requis' });
    }

    const response = await geminiVoiceService.chatWithContext(
      message,
      conversationHistory || []
    );

      res.json({
        text: response.text,
        audioBase64: null, // TTS côté client pour l'instant
        success: true,
      });
  } catch (error) {
    console.error('Erreur chat vocal:', error);
    res.status(500).json({
      error: 'Erreur lors du chat',
      message: error.message,
    });
  }
});

/**
 * Générer une réponse audio à partir d'un texte
 * POST /api/voice-assistant/speak
 * Note: Pour l'instant, on retourne le texte pour TTS côté client
 * L'audio natif Gemini nécessiterait l'API live avec WebSocket
 */
router.post('/speak', authenticateToken, async (req, res) => {
  try {
    const { text, context } = req.body;

    if (!text) {
      return res.status(400).json({ error: 'Texte requis' });
    }

    // Pour l'audio natif Gemini, il faudrait implémenter l'API live
    // Pour l'instant, on retourne null et on utilise TTS côté client
    res.json({
      text: text, // Texte à lire avec TTS côté client
      audioBase64: null, // Pas d'audio natif pour l'instant
      mimeType: null,
      success: true,
    });
  } catch (error) {
    console.error('Erreur génération audio:', error);
    res.status(500).json({
      error: 'Erreur lors de la génération audio',
      message: error.message,
    });
  }
});

/**
 * Analyser une description vocale de diagnostic
 * POST /api/voice-assistant/analyze-diagnostic
 */
router.post('/analyze-diagnostic', authenticateToken, async (req, res) => {
  try {
    const { description } = req.body;

    if (!description) {
      return res.status(400).json({ error: 'Description requise' });
    }

    const analysis = await geminiVoiceService.analyzeDiagnosticDescription(
      description
    );

    res.json({
      ...analysis,
      success: true,
    });
  } catch (error) {
    console.error('Erreur analyse diagnostic:', error);
    res.status(500).json({
      error: 'Erreur lors de l\'analyse',
      message: error.message,
    });
  }
});

module.exports = router;

