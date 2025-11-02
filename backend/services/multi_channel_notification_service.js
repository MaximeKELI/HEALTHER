const axios = require('axios');

/**
 * Service de Notifications Multicanaux
 * 
 * Support pour :
 * - SMS via Twilio
 * - WhatsApp via WhatsApp Business API (Twilio ou Meta)
 * - Email via SMTP (Nodemailer)
 * - Push via Firebase Cloud Messaging (FCM)
 */

class MultiChannelNotificationService {
  constructor() {
    // Twilio Configuration
    this.twilioAccountSid = process.env.TWILIO_ACCOUNT_SID || null;
    this.twilioAuthToken = process.env.TWILIO_AUTH_TOKEN || null;
    this.twilioPhoneNumber = process.env.TWILIO_PHONE_NUMBER || null;
    this.twilioWhatsAppNumber = process.env.TWILIO_WHATSAPP_NUMBER || null;

    // WhatsApp Business API (Meta)
    this.whatsappAccessToken = process.env.WHATSAPP_ACCESS_TOKEN || null;
    this.whatsappPhoneNumberId = process.env.WHATSAPP_PHONE_NUMBER_ID || null;
    this.whatsappBusinessAccountId = process.env.WHATSAPP_BUSINESS_ACCOUNT_ID || null;

    // Email Configuration (SMTP)
    this.smtpHost = process.env.SMTP_HOST || null;
    this.smtpPort = process.env.SMTP_PORT || 587;
    this.smtpUser = process.env.SMTP_USER || null;
    this.smtpPassword = process.env.SMTP_PASSWORD || null;
    this.smtpFrom = process.env.SMTP_FROM || null;

    // Firebase Cloud Messaging
    this.fcmServerKey = process.env.FCM_SERVER_KEY || null;
    this.fcmUrl = 'https://fcm.googleapis.com/fcm/send';
  }

  /**
   * Envoyer une notification SMS via Twilio
   * @param {string} to - Numéro de téléphone destinataire
   * @param {string} message - Message à envoyer
   * @returns {Promise<Object>} Résultat de l'envoi
   */
  async sendSMS(to, message) {
    try {
      if (!this.twilioAccountSid || !this.twilioAuthToken) {
        throw new Error('Twilio non configuré');
      }

      const response = await axios.post(
        `https://api.twilio.com/2010-04-01/Accounts/${this.twilioAccountSid}/Messages.json`,
        new URLSearchParams({
          From: this.twilioPhoneNumber,
          To: to,
          Body: message
        }),
        {
          auth: {
            username: this.twilioAccountSid,
            password: this.twilioAuthToken
          },
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded'
          }
        }
      );

      return {
        success: true,
        channel: 'SMS',
        provider: 'Twilio',
        messageId: response.data.sid,
        status: response.data.status
      };
    } catch (error) {
      console.error('Erreur envoi SMS:', error);
      throw new Error(`Erreur SMS: ${error.message}`);
    }
  }

  /**
   * Envoyer une notification WhatsApp via Twilio
   * @param {string} to - Numéro WhatsApp destinataire
   * @param {string} message - Message à envoyer
   * @returns {Promise<Object>} Résultat de l'envoi
   */
  async sendWhatsAppTwilio(to, message) {
    try {
      if (!this.twilioAccountSid || !this.twilioAuthToken || !this.twilioWhatsAppNumber) {
        throw new Error('WhatsApp Twilio non configuré');
      }

      const response = await axios.post(
        `https://api.twilio.com/2010-04-01/Accounts/${this.twilioAccountSid}/Messages.json`,
        new URLSearchParams({
          From: `whatsapp:${this.twilioWhatsAppNumber}`,
          To: `whatsapp:${to}`,
          Body: message
        }),
        {
          auth: {
            username: this.twilioAccountSid,
            password: this.twilioAuthToken
          },
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded'
          }
        }
      );

      return {
        success: true,
        channel: 'WhatsApp',
        provider: 'Twilio',
        messageId: response.data.sid,
        status: response.data.status
      };
    } catch (error) {
      console.error('Erreur envoi WhatsApp Twilio:', error);
      throw new Error(`Erreur WhatsApp Twilio: ${error.message}`);
    }
  }

  /**
   * Envoyer une notification WhatsApp via Meta Business API
   * @param {string} to - Numéro WhatsApp destinataire
   * @param {string} message - Message à envoyer
   * @returns {Promise<Object>} Résultat de l'envoi
   */
  async sendWhatsAppMeta(to, message) {
    try {
      if (!this.whatsappAccessToken || !this.whatsappPhoneNumberId) {
        throw new Error('WhatsApp Meta non configuré');
      }

      const response = await axios.post(
        `https://graph.facebook.com/v18.0/${this.whatsappPhoneNumberId}/messages`,
        {
          messaging_product: 'whatsapp',
          to: to,
          type: 'text',
          text: {
            body: message
          }
        },
        {
          headers: {
            'Authorization': `Bearer ${this.whatsappAccessToken}`,
            'Content-Type': 'application/json'
          }
        }
      );

      return {
        success: true,
        channel: 'WhatsApp',
        provider: 'Meta',
        messageId: response.data.messages[0].id,
        status: 'sent'
      };
    } catch (error) {
      console.error('Erreur envoi WhatsApp Meta:', error);
      throw new Error(`Erreur WhatsApp Meta: ${error.message}`);
    }
  }

  /**
   * Envoyer un email via SMTP
   * @param {string} to - Adresse email destinataire
   * @param {string} subject - Sujet de l'email
   * @param {string} text - Corps du message (texte)
   * @param {string} html - Corps du message (HTML, optionnel)
   * @returns {Promise<Object>} Résultat de l'envoi
   */
  async sendEmail(to, subject, text, html = null) {
    try {
      if (!this.smtpHost || !this.smtpUser || !this.smtpPassword) {
        throw new Error('SMTP non configuré');
      }

      // Utiliser nodemailer si disponible, sinon axios pour SMTP simple
      const nodemailer = require('nodemailer');

      const transporter = nodemailer.createTransport({
        host: this.smtpHost,
        port: this.smtpPort,
        secure: this.smtpPort === 465,
        auth: {
          user: this.smtpUser,
          pass: this.smtpPassword
        }
      });

      const mailOptions = {
        from: this.smtpFrom || this.smtpUser,
        to: to,
        subject: subject,
        text: text,
        html: html || text
      };

      const info = await transporter.sendMail(mailOptions);

      return {
        success: true,
        channel: 'Email',
        provider: 'SMTP',
        messageId: info.messageId,
        status: 'sent'
      };
    } catch (error) {
      console.error('Erreur envoi email:', error);
      throw new Error(`Erreur Email: ${error.message}`);
    }
  }

  /**
   * Envoyer une notification Push via FCM
   * @param {string|Array<string>} tokens - Token(s) FCM du/des destinataire(s)
   * @param {string} title - Titre de la notification
   * @param {string} body - Corps de la notification
   * @param {Object} data - Données additionnelles (optionnel)
   * @returns {Promise<Object>} Résultat de l'envoi
   */
  async sendPushNotification(tokens, title, body, data = {}) {
    try {
      if (!this.fcmServerKey) {
        throw new Error('FCM non configuré');
      }

      const tokenArray = Array.isArray(tokens) ? tokens : [tokens];

      const response = await axios.post(
        this.fcmUrl,
        {
          registration_ids: tokenArray,
          notification: {
            title: title,
            body: body
          },
          data: data
        },
        {
          headers: {
            'Authorization': `key=${this.fcmServerKey}`,
            'Content-Type': 'application/json'
          }
        }
      );

      return {
        success: true,
        channel: 'Push',
        provider: 'FCM',
        messageId: response.data.multicast_id,
        successCount: response.data.success,
        failureCount: response.data.failure,
        results: response.data.results
      };
    } catch (error) {
      console.error('Erreur envoi Push:', error);
      throw new Error(`Erreur Push: ${error.message}`);
    }
  }

  /**
   * Envoyer une notification sur plusieurs canaux
   * @param {Object} options - Options d'envoi
   * @param {string} options.message - Message à envoyer
   * @param {Array<string>} options.channels - Canaux à utiliser ['SMS', 'WhatsApp', 'Email', 'Push']
   * @param {string} options.phone - Numéro de téléphone (pour SMS/WhatsApp)
   * @param {string} options.email - Adresse email (pour Email)
   * @param {string|Array<string>} options.fcmTokens - Token(s) FCM (pour Push)
   * @param {string} options.subject - Sujet (pour Email)
   * @param {Object} options.data - Données additionnelles (pour Push)
   * @returns {Promise<Object>} Résultats par canal
   */
  async sendMultiChannel(options) {
    const results = {
      success: [],
      errors: []
    };

    const { message, channels, phone, email, fcmTokens, subject, data } = options;

    for (const channel of channels) {
      try {
        let result;

        switch (channel.toUpperCase()) {
          case 'SMS':
            if (!phone) {
              throw new Error('Numéro de téléphone requis pour SMS');
            }
            result = await this.sendSMS(phone, message);
            break;

          case 'WHATSAPP':
            if (!phone) {
              throw new Error('Numéro de téléphone requis pour WhatsApp');
            }
            // Essayer Twilio d'abord, puis Meta
            try {
              result = await this.sendWhatsAppTwilio(phone, message);
            } catch (error) {
              result = await this.sendWhatsAppMeta(phone, message);
            }
            break;

          case 'EMAIL':
            if (!email) {
              throw new Error('Adresse email requise pour Email');
            }
            result = await this.sendEmail(email, subject || 'Notification HEALTHER', message);
            break;

          case 'PUSH':
            if (!fcmTokens) {
              throw new Error('Token(s) FCM requis pour Push');
            }
            result = await this.sendPushNotification(fcmTokens, subject || 'Notification', message, data || {});
            break;

          default:
            throw new Error(`Canal non supporté: ${channel}`);
        }

        results.success.push({
          channel,
          result
        });
      } catch (error) {
        results.errors.push({
          channel,
          error: error.message
        });
      }
    }

    return {
      ...results,
      totalChannels: channels.length,
      successCount: results.success.length,
      errorCount: results.errors.length
    };
  }
}

module.exports = new MultiChannelNotificationService();

