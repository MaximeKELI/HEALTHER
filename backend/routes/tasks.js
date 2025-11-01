const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const taskService = require('../services/task_service');
const Joi = require('joi');

const taskSchema = Joi.object({
  title: Joi.string().required(),
  description: Joi.string().optional(),
  diagnostic_id: Joi.number().integer().optional(),
  assigned_to: Joi.number().integer().optional(),
  priority: Joi.number().integer().min(1).max(10).optional(),
  due_date: Joi.string().isoDate().optional(),
  metadata: Joi.object().optional(),
});

/**
 * Créer une tâche
 * POST /api/tasks
 */
router.post('/', authenticateToken, async (req, res) => {
  try {
    const { error, value } = taskSchema.validate(req.body);
    if (error) {
      return res.status(400).json({ error: error.details[0].message });
    }
    
    const taskId = await taskService.createTask({
      ...value,
      created_by: req.user.id,
    }, req.io);
    
    res.status(201).json({
      id: taskId,
      message: 'Tâche créée',
    });
  } catch (error) {
    console.error('Erreur création tâche:', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

/**
 * Obtenir les tâches de l'utilisateur
 * GET /api/tasks?status=pending
 */
router.get('/', authenticateToken, async (req, res) => {
  try {
    const status = req.query.status || null;
    const tasks = await taskService.getUserTasks(req.user.id, status);
    res.json(tasks);
  } catch (error) {
    console.error('Erreur récupération tâches:', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

/**
 * Mettre à jour le statut d'une tâche
 * PATCH /api/tasks/:id/status
 */
router.patch('/:id/status', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;
    
    if (!status || !['pending', 'in_progress', 'completed', 'cancelled'].includes(status)) {
      return res.status(400).json({ error: 'Statut invalide' });
    }
    
    await taskService.updateTaskStatus(parseInt(id), status, req.user.id);
    res.json({ message: 'Statut mis à jour' });
  } catch (error) {
    console.error('Erreur mise à jour tâche:', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

/**
 * Obtenir les tâches en retard (admin/supervisor)
 * GET /api/tasks/overdue
 */
router.get('/overdue', authenticateToken, async (req, res) => {
  try {
    // Vérifier permissions (admin ou supervisor)
    if (!['admin', 'supervisor'].includes(req.user.role)) {
      return res.status(403).json({ error: 'Permission refusée' });
    }
    
    const tasks = await taskService.getOverdueTasks();
    res.json(tasks);
  } catch (error) {
    console.error('Erreur récupération tâches en retard:', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

module.exports = router;
