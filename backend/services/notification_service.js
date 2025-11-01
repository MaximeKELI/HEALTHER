const { dbRun, dbGet, dbAll } = require('../config/database');

/**
 * Service de notifications (in-app, SMS, WhatsApp)
 */
class NotificationService {
  /**
   * Créer une notification in-app (avec WebSocket si disponible)
   */
  async createInAppNotification(userId, type, title, message, resourceType = null, resourceId = null, io = null) {
    try {
      const result = await dbRun(
        `INSERT INTO notifications (user_id, type, title, message, resource_type, resource_id)
         VALUES (?, ?, ?, ?, ?, ?)`,
        [userId, type, title, message, resourceType, resourceId]
      );
      
      // Envoyer via WebSocket si disponible
      if (io) {
        io.to(`user-${userId}`).emit('notification', {
          id: result.lastID,
          type,
          title,
          message,
          resource_type: resourceType,
          resource_id: resourceId,
          created_at: new Date().toISOString()
        });
      }
      
      return result.lastID;
    } catch (error) {
      console.error('Erreur création notification:', error);
      throw error;
    }
  }

  /**
   * Notifier plusieurs utilisateurs
   */
  async notifyUsers(userIds, type, title, message, resourceType = null, resourceId = null, io = null) {
    const promises = userIds.map(userId => 
      this.createInAppNotification(userId, type, title, message, resourceType, resourceId, io)
    );
    await Promise.all(promises);
  }

  /**
   * Notifier les superviseurs d'une région
   */
  async notifySupervisorsInRegion(region, type, title, message, resourceType = null, resourceId = null, io = null) {
    try {
      const supervisors = await dbAll(
        `SELECT id FROM users WHERE role IN ('supervisor', 'epidemiologist', 'admin')
         AND centre_sante LIKE ?`,
        [`%${region}%`]
      );
      
      if (supervisors.length > 0) {
        const userIds = supervisors.map(s => s.id);
        await this.notifyUsers(userIds, type, title, message, resourceType, resourceId, io);
      }
    } catch (error) {
      console.error('Erreur notification superviseurs:', error);
    }
  }

  /**
   * Obtenir les notifications d'un utilisateur
   */
  async getUserNotifications(userId, limit = 50, offset = 0) {
    return await dbAll(
      `SELECT * FROM notifications 
       WHERE user_id = ? OR user_id IS NULL
       ORDER BY created_at DESC 
       LIMIT ? OFFSET ?`,
      [userId, limit, offset]
    );
  }

  /**
   * Marquer une notification comme lue
   */
  async markAsRead(notificationId) {
    await dbRun(
      'UPDATE notifications SET read = 1 WHERE id = ?',
      [notificationId]
    );
  }

  /**
   * Envoyer une notification SMS (placeholder - nécessite API-KEY)
   */
  async sendSMS(phoneNumber, message) {
    const smsApiKey = process.env.SMS_API_KEY;
    const smsApiUrl = process.env.SMS_API_URL || 'https://api.sms-provider.com/send';
    
    if (!smsApiKey) {
      console.warn('⚠️ SMS_API_KEY non configuré - notification SMS non envoyée');
      console.log(`📱 SMS simulé pour ${phoneNumber}: ${message}`);
      return { success: false, reason: 'API_KEY non configurée' };
    }

    try {
      // Ici vous intégreriez l'API SMS réelle (Twilio, AWS SNS, etc.)
      // Exemple avec fetch/axios:
      /*
      const response = await axios.post(smsApiUrl, {
        to: phoneNumber,
        message: message
      }, {
        headers: {
          'Authorization': `Bearer ${smsApiKey}`,
          'Content-Type': 'application/json'
        }
      });
      return { success: true, messageId: response.data.id };
      */
      
      // Pour l'instant, retourner un placeholder
      console.log(`📱 SMS envoyé (simulé - nécessite API-KEY): ${phoneNumber} - ${message}`);
      return { success: true, simulated: true };
    } catch (error) {
      console.error('Erreur envoi SMS:', error);
      throw error;
    }
  }

  /**
   * Envoyer une notification WhatsApp (placeholder - nécessite API-KEY)
   */
  async sendWhatsApp(phoneNumber, message) {
    const whatsappApiKey = process.env.WHATSAPP_API_KEY;
    const whatsappApiUrl = process.env.WHATSAPP_API_URL || 'https://api.whatsapp.com/v1/messages';
    
    if (!whatsappApiKey) {
      console.warn('⚠️ WHATSAPP_API_KEY non configuré - notification WhatsApp non envoyée');
      console.log(`💬 WhatsApp simulé pour ${phoneNumber}: ${message}`);
      return { success: false, reason: 'API_KEY non configurée' };
    }

    try {
      // Ici vous intégreriez l'API WhatsApp Business (Twilio, Meta, etc.)
      // Exemple avec fetch/axios:
      /*
      const response = await axios.post(whatsappApiUrl, {
        to: phoneNumber,
        message: message,
        type: 'text'
      }, {
        headers: {
          'Authorization': `Bearer ${whatsappApiKey}`,
          'Content-Type': 'application/json'
        }
      });
      return { success: true, messageId: response.data.id };
      */
      
      console.log(`💬 WhatsApp envoyé (simulé - nécessite API-KEY): ${phoneNumber} - ${message}`);
      return { success: true, simulated: true };
    } catch (error) {
      console.error('Erreur envoi WhatsApp:', error);
      throw error;
    }
  }

  /**
   * Envoyer une notification push (nécessite FCM/SNS - API-KEY)
   */
  async sendPushNotification(userId, title, message, data = {}) {
    const fcmApiKey = process.env.FCM_SERVER_KEY;
    
    if (!fcmApiKey) {
      console.warn('⚠️ FCM_SERVER_KEY non configuré - notification push non envoyée');
      return { success: false, reason: 'API_KEY non configurée' };
    }

    try {
      // Récupérer le device token de l'utilisateur
      // Ici vous utiliseriez FCM (Firebase Cloud Messaging) ou AWS SNS
      // Exemple avec FCM:
      /*
      const fcm = require('firebase-admin');
      const message = {
        notification: { title, body: message },
        data: data,
        token: deviceToken
      };
      await fcm.messaging().send(message);
      */
      
      console.log(`📲 Push notification (simulé - nécessite FCM_SERVER_KEY): ${userId} - ${title}`);
      return { success: true, simulated: true };
    } catch (error) {
      console.error('Erreur envoi push:', error);
      throw error;
    }
  }
}

module.exports = new NotificationService();

