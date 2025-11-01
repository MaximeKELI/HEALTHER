const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const { dbRun, dbGet, dbAll } = require('../config/database');

// Obtenir la file d'attente offline d'un utilisateur
router.get('/', authenticateToken, async (req, res) => {
  try {
    const queue = await dbAll(
      `SELECT * FROM offline_queue 
       WHERE user_id = ? AND status = 'pending'
       ORDER BY created_at ASC`,
      [req.user.id]
    );

    res.json(queue.map(item => ({
      ...item,
      data: item.data ? JSON.parse(item.data) : null
    })));
  } catch (error) {
    console.error('Erreur récupération file:', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

// Synchroniser un item de la file
router.post('/sync/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const queueItem = await dbGet('SELECT * FROM offline_queue WHERE id = ? AND user_id = ?', [id, req.user.id]);
    
    if (!queueItem) {
      return res.status(404).json({ error: 'Item non trouvé' });
    }

    // Marquer comme en cours de sync
    await dbRun(
      `UPDATE offline_queue SET status = 'syncing' WHERE id = ?`,
      [id]
    );

    // Ici vous appelleriez l'API réelle pour synchroniser
    // Pour l'instant, marquer comme synchronisé
    await dbRun(
      `UPDATE offline_queue SET status = 'synced', synced_at = CURRENT_TIMESTAMP WHERE id = ?`,
      [id]
    );

    res.json({ message: 'Item synchronisé', id });
  } catch (error) {
    await dbRun(
      `UPDATE offline_queue SET status = 'failed', retry_count = retry_count + 1, last_error = ? WHERE id = ?`,
      [error.message, req.params.id]
    );
    console.error('Erreur sync:', error);
    res.status(500).json({ error: 'Erreur synchronisation' });
  }
});

// Supprimer un item synchronisé
router.delete('/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    await dbRun('DELETE FROM offline_queue WHERE id = ? AND user_id = ? AND status = "synced"', [id, req.user.id]);
    res.json({ message: 'Item supprimé' });
  } catch (error) {
    console.error('Erreur suppression:', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

module.exports = router;

