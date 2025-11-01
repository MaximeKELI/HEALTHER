const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const { checkPermission } = require('../middleware/permissions');
const { dbRun, dbGet, dbAll } = require('../config/database');
const Joi = require('joi');

const commentSchema = Joi.object({
  diagnostic_id: Joi.number().integer().required(),
  comment: Joi.string().required(),
  parent_id: Joi.number().integer().optional(),
  mentions: Joi.array().items(Joi.number().integer()).optional(),
});

// Créer un commentaire
router.post('/', authenticateToken, checkPermission('comments', 'create'), async (req, res) => {
  try {
    const { error, value } = commentSchema.validate(req.body);
    if (error) {
      return res.status(400).json({ error: error.details[0].message });
    }

    // Extraire les mentions (@username ou @userId)
    const mentions = value.mentions || [];
    
    const result = await dbRun(
      `INSERT INTO comments (diagnostic_id, user_id, comment, parent_id, mentions)
       VALUES (?, ?, ?, ?, ?)`,
      [
        value.diagnostic_id,
        req.user.id,
        value.comment,
        value.parent_id || null,
        mentions.length > 0 ? JSON.stringify(mentions) : null
      ]
    );
    
    // Notifier les utilisateurs mentionnés
    if (mentions.length > 0) {
      const notificationService = require('../services/notification_service');
      for (const mentionedUserId of mentions) {
        await notificationService.createInAppNotification(
          mentionedUserId,
          'mention',
          'Vous avez été mentionné',
          `${req.user.username} vous a mentionné dans un commentaire`,
          'comment',
          result.lastID,
          req.io
        );
      }
    }

    res.status(201).json({
      id: result.lastID,
      message: 'Commentaire ajouté'
    });
  } catch (error) {
    console.error('Erreur création commentaire:', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

// Obtenir les commentaires d'un diagnostic
router.get('/diagnostic/:diagnostic_id', authenticateToken, checkPermission('comments', 'read'), async (req, res) => {
  try {
    const { diagnostic_id } = req.params;
    const comments = await dbAll(
      `SELECT c.*, u.username, u.nom, u.prenom 
       FROM comments c
       JOIN users u ON c.user_id = u.id
       WHERE c.diagnostic_id = ?
       ORDER BY c.created_at ASC`,
      [diagnostic_id]
    );

    res.json(comments);
  } catch (error) {
    console.error('Erreur récupération commentaires:', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

module.exports = router;

