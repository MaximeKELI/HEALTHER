const { dbRun, dbGet, dbAll } = require('../config/database');
const notificationService = require('./notification_service');
const dayjs = require('dayjs');

/**
 * Créer une tâche
 * @param {Object} taskData - Données de la tâche
 * @param {Object} io - Instance Socket.IO
 * @returns {Promise<number>} - ID de la tâche
 */
async function createTask(taskData, io = null) {
  const {
    title,
    description,
    diagnostic_id,
    assigned_to,
    created_by,
    priority = 5,
    due_date,
    metadata = {},
  } = taskData;
  
  const result = await dbRun(
    `INSERT INTO tasks (title, description, diagnostic_id, assigned_to, created_by, priority, due_date, metadata)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
    [
      title,
      description || null,
      diagnostic_id || null,
      assigned_to || null,
      created_by,
      priority,
      due_date || null,
      JSON.stringify(metadata),
    ]
  );
  
  // Notifier l'utilisateur assigné
  if (assigned_to && io) {
    await notificationService.createInAppNotification(
      assigned_to,
      'task_assigned',
      'Nouvelle tâche assignée',
      `Une nouvelle tâche vous a été assignée: ${title}`,
      'task',
      result.lastID,
      io
    );
  }
  
  return result.lastID;
}

/**
 * Obtenir les tâches d'un utilisateur
 * @param {number} userId - ID utilisateur
 * @param {string} status - Statut (pending, in_progress, completed)
 * @returns {Promise<Array>} - Tâches
 */
async function getUserTasks(userId, status = null) {
  let sql = `SELECT t.*, 
     u_assigned.username as assigned_username,
     u_creator.username as creator_username,
     d.maladie_type, d.statut as diagnostic_status
     FROM tasks t
     LEFT JOIN users u_assigned ON t.assigned_to = u_assigned.id
     LEFT JOIN users u_creator ON t.created_by = u_creator.id
     LEFT JOIN diagnostics d ON t.diagnostic_id = d.id
     WHERE t.assigned_to = ? OR t.created_by = ?`;
  const params = [userId, userId];
  
  if (status) {
    sql += ' AND t.status = ?';
    params.push(status);
  }
  
  sql += ' ORDER BY t.priority DESC, t.created_at DESC';
  
  const tasks = await dbAll(sql, params);
  
  return tasks.map(t => ({
    ...t,
    metadata: t.metadata ? JSON.parse(t.metadata) : {},
  }));
}

/**
 * Mettre à jour le statut d'une tâche
 * @param {number} taskId - ID de la tâche
 * @param {string} status - Nouveau statut
 * @param {number} userId - ID utilisateur
 * @returns {Promise<void>}
 */
async function updateTaskStatus(taskId, status, userId) {
  await dbRun(
    `UPDATE tasks 
     SET status = ?, updated_at = CURRENT_TIMESTAMP
     WHERE id = ? AND (assigned_to = ? OR created_by = ?)`,
    [status, taskId, userId, userId]
  );
}

/**
 * Obtenir les tâches en retard
 * @returns {Promise<Array>} - Tâches en retard
 */
async function getOverdueTasks() {
  const today = dayjs().format('YYYY-MM-DD');
  
  const tasks = await dbAll(
    `SELECT t.*, u.username as assigned_username
     FROM tasks t
     LEFT JOIN users u ON t.assigned_to = u.id
     WHERE t.status NOT IN ('completed', 'cancelled')
     AND t.due_date IS NOT NULL
     AND t.due_date < ?
     ORDER BY t.due_date ASC`,
    [today]
  );
  
  return tasks.map(t => ({
    ...t,
    metadata: t.metadata ? JSON.parse(t.metadata) : {},
  }));
}

module.exports = {
  createTask,
  getUserTasks,
  updateTaskStatus,
  getOverdueTasks,
};
