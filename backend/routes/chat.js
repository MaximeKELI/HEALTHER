const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const chatService = require('../services/chat_service');
const Joi = require('joi');

const messageSchema = Joi.object({
  diagnostic_id: Joi.number().integer().required(),
  message: Joi.string().required(),
  mentions: Joi.array().items(Joi.number().integer()).optional(),
  attachments: Joi.array().items(Joi.number().integer()).optional(),
});

/**
 * Envoyer un message
 * POST /api/chat/messages
 */
router.post('/messages', authenticateToken, async (req, res) => {
  try {
    const { error, value } = messageSchema.validate(req.body);
    if (error) {
      return res.status(400).json({ error: error.details[0].message });
    }
    
    const messageId = await chatService.sendMessage(
      value.diagnostic_id,
      req.user.id,
      value.message,
      value.mentions || [],
      value.attachments || [],
      req.io
    );
    
    res.status(201).json({
      id: messageId,
      message: 'Message envoyé',
    });
  } catch (error) {
    console.error('Erreur envoi message:', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

/**
 * Obtenir les messages d'un diagnostic
 * GET /api/chat/diagnostic/:diagnostic_id
 */
router.get('/diagnostic/:diagnostic_id', authenticateToken, async (req, res) => {
  try {
    const { diagnostic_id } = req.params;
    const limit = parseInt(req.query.limit || '50', 10);
    const offset = parseInt(req.query.offset || '0', 10);
    
    const messages = await chatService.getMessages(parseInt(diagnostic_id), limit, offset);
    res.json(messages);
  } catch (error) {
    console.error('Erreur récupération messages:', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

module.exports = router;
