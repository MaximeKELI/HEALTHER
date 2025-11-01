const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const { dbRun, dbGet, dbAll } = require('../config/database');
const notificationService = require('../services/notification_service');

// Obtenir les notifications de l'utilisateur
router.get('/', authenticateToken, async (req, res) => {
  try {
    const { limit = 50, offset = 0, unread_only = false } = req.query;
    
    let sql = `SELECT * FROM notifications 
               WHERE user_id = ? OR user_id IS NULL`;
    
    if (unread_only === 'true') {
      sql += ' AND read = 0';
    }
    
    sql += ' ORDER BY created_at DESC LIMIT ? OFFSET ?';
    
    const notifications = await dbAll(sql, [req.user.id, parseInt(limit), parseInt(offset)]);
    
    res.json(notifications);
  } catch (error) {
    console.error('Erreur récupération notifications:', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

// Marquer une notification comme lue
router.put('/:id/read', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    await notificationService.markAsRead(id);
    res.json({ message: 'Notification marquée comme lue' });
  } catch (error) {
    console.error('Erreur marquage notification:', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

// Marquer toutes les notifications comme lues
router.put('/read-all', authenticateToken, async (req, res) => {
  try {
    await dbRun(
      'UPDATE notifications SET read = 1 WHERE user_id = ? OR user_id IS NULL',
      [req.user.id]
    );
    res.json({ message: 'Toutes les notifications marquées comme lues' });
  } catch (error) {
    console.error('Erreur marquage notifications:', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

// Compter les notifications non lues
router.get('/unread-count', authenticateToken, async (req, res) => {
  try {
    const result = await dbGet(
      `SELECT COUNT(*) as count FROM notifications 
       WHERE (user_id = ? OR user_id IS NULL) AND read = 0`,
      [req.user.id]
    );
    res.json({ count: result.count || 0 });
  } catch (error) {
    console.error('Erreur comptage notifications:', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

module.exports = router;

