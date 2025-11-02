const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const { checkPermission } = require('../middleware/permissions');
const multiChannelNotificationService = require('../services/multi_channel_notification_service');

/**
 * Routes pour Notifications Multicanaux
 */

// Envoyer SMS
router.post('/sms', authenticateToken, checkPermission('notifications', 'create'), async (req, res) => {
  try {
    const { to, message } = req.body;

    if (!to || !message) {
      return res.status(400).json({
        success: false,
        error: 'Numéro de téléphone et message requis'
      });
    }

    const result = await multiChannelNotificationService.sendSMS(to, message);

    res.json({
      success: true,
      ...result
    });
  } catch (error) {
    console.error('Erreur envoi SMS:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Envoyer WhatsApp
router.post('/whatsapp', authenticateToken, checkPermission('notifications', 'create'), async (req, res) => {
  try {
    const { to, message, provider } = req.body;

    if (!to || !message) {
      return res.status(400).json({
        success: false,
        error: 'Numéro de téléphone et message requis'
      });
    }

    let result;
    if (provider === 'meta' || !provider) {
      // Essayer Meta d'abord, puis Twilio en fallback
      try {
        result = await multiChannelNotificationService.sendWhatsAppMeta(to, message);
      } catch (error) {
        result = await multiChannelNotificationService.sendWhatsAppTwilio(to, message);
      }
    } else {
      result = await multiChannelNotificationService.sendWhatsAppTwilio(to, message);
    }

    res.json({
      success: true,
      ...result
    });
  } catch (error) {
    console.error('Erreur envoi WhatsApp:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Envoyer Email
router.post('/email', authenticateToken, checkPermission('notifications', 'create'), async (req, res) => {
  try {
    const { to, subject, text, html } = req.body;

    if (!to || !text) {
      return res.status(400).json({
        success: false,
        error: 'Adresse email et message requis'
      });
    }

    const result = await multiChannelNotificationService.sendEmail(
      to,
      subject || 'Notification HEALTHER',
      text,
      html
    );

    res.json({
      success: true,
      ...result
    });
  } catch (error) {
    console.error('Erreur envoi Email:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Envoyer Push Notification
router.post('/push', authenticateToken, checkPermission('notifications', 'create'), async (req, res) => {
  try {
    const { tokens, title, body, data } = req.body;

    if (!tokens || !body) {
      return res.status(400).json({
        success: false,
        error: 'Token(s) FCM et message requis'
      });
    }

    const result = await multiChannelNotificationService.sendPushNotification(
      tokens,
      title || 'Notification',
      body,
      data || {}
    );

    res.json({
      success: true,
      ...result
    });
  } catch (error) {
    console.error('Erreur envoi Push:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Envoyer sur plusieurs canaux
router.post('/multichannel', authenticateToken, checkPermission('notifications', 'create'), async (req, res) => {
  try {
    const { message, channels, phone, email, fcmTokens, subject, data } = req.body;

    if (!message || !channels || !Array.isArray(channels)) {
      return res.status(400).json({
        success: false,
        error: 'Message et liste de canaux requis'
      });
    }

    const result = await multiChannelNotificationService.sendMultiChannel({
      message,
      channels,
      phone,
      email,
      fcmTokens,
      subject,
      data
    });

    res.json({
      success: result.errorCount === 0,
      ...result
    });
  } catch (error) {
    console.error('Erreur envoi multicanaux:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

module.exports = router;

