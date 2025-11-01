const { dbRun, dbGet, dbAll } = require('../config/database');
const notificationService = require('./notification_service');

/**
 * Envoyer un message dans le chat d'un diagnostic
 * @param {number} diagnosticId - ID du diagnostic
 * @param {number} userId - ID de l'utilisateur
 * @param {string} message - Message
 * @param {Array<number>} mentions - IDs des utilisateurs mentionnés
 * @param {Array<number>} attachments - IDs des pièces jointes
 * @param {Object} io - Instance Socket.IO
 * @returns {Promise<number>} - ID du message
 */
async function sendMessage(diagnosticId, userId, message, mentions = [], attachments = [], io = null) {
  const result = await dbRun(
    `INSERT INTO chat_messages (diagnostic_id, user_id, message, mentions, attachments)
     VALUES (?, ?, ?, ?, ?)`,
    [
      diagnosticId,
      userId,
      message,
      mentions.length > 0 ? JSON.stringify(mentions) : null,
      attachments.length > 0 ? JSON.stringify(attachments) : null,
    ]
  );
  
  // Notifier les utilisateurs mentionnés
  if (mentions.length > 0 && io) {
    for (const mentionedUserId of mentions) {
      await notificationService.createInAppNotification(
        mentionedUserId,
        'mention',
        'Vous avez été mentionné',
        `Vous avez été mentionné dans le chat du diagnostic #${diagnosticId}`,
        'chat',
        diagnosticId,
        io
      );
    }
  }
  
  // Émettre le message via WebSocket à tous les utilisateurs suivant ce diagnostic
  if (io) {
    io.to(`diagnostic-${diagnosticId}`).emit('new-message', {
      id: result.lastID,
      diagnostic_id: diagnosticId,
      user_id: userId,
      message,
      mentions,
      attachments,
      created_at: new Date().toISOString(),
    });
  }
  
  return result.lastID;
}

/**
 * Obtenir les messages d'un diagnostic
 * @param {number} diagnosticId - ID du diagnostic
 * @param {number} limit - Nombre de messages à récupérer
 * @param {number} offset - Offset pour pagination
 * @returns {Promise<Array>} - Messages
 */
async function getMessages(diagnosticId, limit = 50, offset = 0) {
  const messages = await dbAll(
    `SELECT cm.*, u.username, u.nom, u.prenom, u.role
     FROM chat_messages cm
     JOIN users u ON cm.user_id = u.id
     WHERE cm.diagnostic_id = ?
     ORDER BY cm.created_at DESC
     LIMIT ? OFFSET ?`,
    [diagnosticId, limit, offset]
  );
  
  return messages.map(m => ({
    ...m,
    mentions: m.mentions ? JSON.parse(m.mentions) : [],
    attachments: m.attachments ? JSON.parse(m.attachments) : [],
  }));
}

module.exports = {
  sendMessage,
  getMessages,
};
