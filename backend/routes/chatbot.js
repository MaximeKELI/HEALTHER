const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const geminiService = require('../services/gemini_service');
const { dbRun, dbGet, dbAll } = require('../config/database');
const Joi = require('joi');

// Schéma de validation pour les messages
const messageSchema = Joi.object({
  message: Joi.string().required().min(1).max(2000),
  conversation_id: Joi.number().integer().optional(),
  context: Joi.object({
    region: Joi.string().optional(),
    prefecture: Joi.string().optional(),
    maladie_type: Joi.string().optional(),
  }).optional(),
});

// Créer ou récupérer une conversation
router.get('/conversation', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;
    
    // Chercher une conversation existante non fermée
    let conversation = await dbGet(
      'SELECT * FROM chatbot_conversations WHERE user_id = ? AND closed_at IS NULL ORDER BY created_at DESC LIMIT 1',
      [userId]
    );

    // Si aucune conversation ouverte, en créer une nouvelle
    if (!conversation) {
      const result = await dbRun(
        'INSERT INTO chatbot_conversations (user_id, title) VALUES (?, ?)',
        [userId, 'Nouvelle conversation']
      );
      conversation = await dbGet(
        'SELECT * FROM chatbot_conversations WHERE id = ?',
        [result.lastID]
      );
    }

    // Récupérer les messages de la conversation
    const messages = await dbAll(
      'SELECT * FROM chatbot_messages WHERE conversation_id = ? ORDER BY created_at ASC',
      [conversation.id]
    );

    res.json({
      conversation: {
        id: conversation.id,
        title: conversation.title,
        created_at: conversation.created_at,
      },
      messages: messages.map(msg => ({
        id: msg.id,
        role: msg.role,
        message: msg.message,
        created_at: msg.created_at,
      })),
    });
  } catch (error) {
    console.error('Erreur récupération conversation:', error);
    res.status(500).json({ error: 'Erreur serveur lors de la récupération de la conversation' });
  }
});

// Envoyer un message au chatbot
router.post('/message', authenticateToken, async (req, res) => {
  try {
    const { error, value } = messageSchema.validate(req.body);
    if (error) {
      return res.status(400).json({ error: error.details[0].message });
    }

    const userId = req.user.id;
    const { message, conversation_id, context } = value;

    // Vérifier que le service Gemini est disponible
    if (!geminiService.isAvailable()) {
      return res.status(503).json({ 
        error: 'Service chatbot non disponible. Vérifiez la configuration de GEMINI_API_KEY.' 
      });
    }

    // Récupérer ou créer la conversation
    let conversation;
    if (conversation_id) {
      conversation = await dbGet(
        'SELECT * FROM chatbot_conversations WHERE id = ? AND user_id = ?',
        [conversation_id, userId]
      );
      if (!conversation) {
        return res.status(404).json({ error: 'Conversation non trouvée' });
      }
    } else {
      const result = await dbRun(
        'INSERT INTO chatbot_conversations (user_id, title) VALUES (?, ?)',
        [userId, message.substring(0, 50) || 'Nouvelle conversation']
      );
      conversation = await dbGet(
        'SELECT * FROM chatbot_conversations WHERE id = ?',
        [result.lastID]
      );
    }

    // Sauvegarder le message de l'utilisateur
    const userMessageResult = await dbRun(
      'INSERT INTO chatbot_messages (conversation_id, role, message) VALUES (?, ?, ?)',
      [conversation.id, 'user', message]
    );

    // Récupérer l'historique de conversation
    const conversationHistory = await dbAll(
      'SELECT * FROM chatbot_messages WHERE conversation_id = ? ORDER BY created_at ASC',
      [conversation.id]
    );

    // Construire le contexte utilisateur
    const userContext = {
      role: req.user.role,
      region: context?.region || req.user.region,
      prefecture: context?.prefecture || req.user.prefecture,
      centreSante: req.user.centre_sante,
    };

    // Générer la réponse avec Gemini
    const aiResponse = await geminiService.generateResponse(
      message,
      conversationHistory.map(msg => ({
        role: msg.role,
        message: msg.message,
      })),
      userContext
    );

    // Sauvegarder la réponse de l'IA
    const aiMessageResult = await dbRun(
      'INSERT INTO chatbot_messages (conversation_id, role, message) VALUES (?, ?, ?)',
      [conversation.id, 'assistant', aiResponse]
    );

    // Mettre à jour le titre de la conversation si c'est le premier message
    if (conversationHistory.length === 0) {
      await dbRun(
        'UPDATE chatbot_conversations SET title = ? WHERE id = ?',
        [message.substring(0, 50) || 'Nouvelle conversation', conversation.id]
      );
    }

    res.json({
      conversation_id: conversation.id,
      user_message: {
        id: userMessageResult.lastID,
        role: 'user',
        message: message,
      },
      ai_message: {
        id: aiMessageResult.lastID,
        role: 'assistant',
        message: aiResponse,
      },
    });
  } catch (error) {
    console.error('Erreur envoi message chatbot:', error);
    res.status(500).json({ 
      error: error.message || 'Erreur serveur lors de l\'envoi du message' 
    });
  }
});

// Récupérer toutes les conversations d'un utilisateur
router.get('/conversations', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;
    const conversations = await dbAll(
      'SELECT * FROM chatbot_conversations WHERE user_id = ? ORDER BY created_at DESC',
      [userId]
    );

    res.json(conversations.map(conv => ({
      id: conv.id,
      title: conv.title,
      created_at: conv.created_at,
      closed_at: conv.closed_at,
    })));
  } catch (error) {
    console.error('Erreur récupération conversations:', error);
    res.status(500).json({ error: 'Erreur serveur lors de la récupération des conversations' });
  }
});

// Fermer une conversation
router.post('/conversation/:id/close', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    const conversation = await dbGet(
      'SELECT * FROM chatbot_conversations WHERE id = ? AND user_id = ?',
      [id, userId]
    );

    if (!conversation) {
      return res.status(404).json({ error: 'Conversation non trouvée' });
    }

    await dbRun(
      'UPDATE chatbot_conversations SET closed_at = CURRENT_TIMESTAMP WHERE id = ?',
      [id]
    );

    res.json({ message: 'Conversation fermée avec succès' });
  } catch (error) {
    console.error('Erreur fermeture conversation:', error);
    res.status(500).json({ error: 'Erreur serveur lors de la fermeture de la conversation' });
  }
});

module.exports = router;

