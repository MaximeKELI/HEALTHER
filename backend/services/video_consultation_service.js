const axios = require('axios');

/**
 * Service de Vidéoconsultation / Télémédecine
 * 
 * Support pour :
 * - Agora.io (Recommandé)
 * - Twilio Video (Alternative)
 * - Jitsi Meet (Open-source, alternative)
 */

class VideoConsultationService {
  constructor() {
    // Agora Configuration
    this.agoraAppId = process.env.AGORA_APP_ID || null;
    this.agoraAppCertificate = process.env.AGORA_APP_CERTIFICATE || null;
    
    // Twilio Video Configuration
    this.twilioAccountSid = process.env.TWILIO_ACCOUNT_SID || null;
    this.twilioAuthToken = process.env.TWILIO_AUTH_TOKEN || null;
    
    // Provider par défaut
    this.provider = process.env.VIDEO_PROVIDER || 'agora'; // 'agora', 'twilio', 'jitsi'
  }

  /**
   * Générer un token Agora pour un utilisateur
   * @param {string} channelName - Nom du canal
   * @param {number} userId - ID de l'utilisateur (0 pour utilisateur anonyme)
   * @param {number} role - Rôle (1 = Publisher, 2 = Subscriber)
   * @param {number} expireTime - Temps d'expiration en secondes (par défaut 24h)
   * @returns {Promise<Object>} Token et informations de canal
   */
  async generateAgoraToken(channelName, userId, role = 1, expireTime = 86400) {
    try {
      if (!this.agoraAppId || !this.agoraAppCertificate) {
        throw new Error('Agora non configuré. Configurez AGORA_APP_ID et AGORA_APP_CERTIFICATE');
      }

      // Calculer le temps d'expiration
      const currentTimestamp = Math.floor(Date.now() / 1000);
      const privilegeExpiredTs = currentTimestamp + expireTime;

      // Générer le token (simplifié - utiliser la SDK Agora en production)
      // Pour une implémentation complète, utiliser: AgoraRtcTokenBuilder
      const token = this._generateSimpleToken(channelName, userId, role, privilegeExpiredTs);

      return {
        success: true,
        provider: 'agora',
        appId: this.agoraAppId,
        channelName: channelName,
        userId: userId,
        token: token,
        expireTime: privilegeExpiredTs
      };
    } catch (error) {
      console.error('Erreur génération token Agora:', error);
      throw new Error(`Erreur Agora: ${error.message}`);
    }
  }

  /**
   * Générer un token Twilio Video
   * @param {string} roomName - Nom de la salle
   * @param {string} identity - Identité de l'utilisateur
   * @returns {Promise<Object>} Token Twilio
   */
  async generateTwilioToken(roomName, identity) {
    try {
      if (!this.twilioAccountSid || !this.twilioAuthToken) {
        throw new Error('Twilio Video non configuré');
      }

      // Utiliser Twilio Access Token Generator
      // En production, utiliser: twilio.jwt.AccessToken
      const token = this._generateTwilioAccessToken(roomName, identity);

      return {
        success: true,
        provider: 'twilio',
        accountSid: this.twilioAccountSid,
        roomName: roomName,
        identity: identity,
        token: token
      };
    } catch (error) {
      console.error('Erreur génération token Twilio:', error);
      throw new Error(`Erreur Twilio: ${error.message}`);
    }
  }

  /**
   * Créer une session de consultation vidéo
   * @param {number} consultationId - ID de la consultation
   * @param {number} doctorId - ID du médecin
   * @param {number} patientId - ID du patient
   * @param {string} provider - Provider ('agora', 'twilio', 'jitsi')
   * @returns {Promise<Object>} Informations de session
   */
  async createConsultationSession(consultationId, doctorId, patientId, provider = null) {
    try {
      const actualProvider = provider || this.provider;
      const channelName = `consultation-${consultationId}`;

      let sessionData;

      switch (actualProvider) {
        case 'agora':
          // Générer tokens pour médecin et patient
          const doctorToken = await this.generateAgoraToken(channelName, doctorId, 1);
          const patientToken = await this.generateAgoraToken(channelName, patientId, 1);
          
          sessionData = {
            provider: 'agora',
            channelName: channelName,
            appId: this.agoraAppId,
            doctor: {
              userId: doctorId,
              token: doctorToken.token
            },
            patient: {
              userId: patientId,
              token: patientToken.token
            }
          };
          break;

        case 'twilio':
          const doctorTwilioToken = await this.generateTwilioToken(channelName, `doctor-${doctorId}`);
          const patientTwilioToken = await this.generateTwilioToken(channelName, `patient-${patientId}`);
          
          sessionData = {
            provider: 'twilio',
            roomName: channelName,
            doctor: {
              identity: `doctor-${doctorId}`,
              token: doctorTwilioToken.token
            },
            patient: {
              identity: `patient-${patientId}`,
              token: patientTwilioToken.token
            }
          };
          break;

        case 'jitsi':
          // Jitsi est gratuit et ne nécessite pas de token côté serveur
          sessionData = {
            provider: 'jitsi',
            roomName: channelName,
            serverUrl: process.env.JITSI_SERVER_URL || 'https://meet.jit.si',
            doctor: {
              userId: doctorId
            },
            patient: {
              userId: patientId
            }
          };
          break;

        default:
          throw new Error(`Provider non supporté: ${actualProvider}`);
      }

      return {
        success: true,
        consultationId: consultationId,
        ...sessionData,
        createdAt: new Date().toISOString()
      };
    } catch (error) {
      console.error('Erreur création session:', error);
      throw error;
    }
  }

  /**
   * Générer un token simple (à remplacer par SDK Agora en production)
   * @private
   */
  _generateSimpleToken(channelName, userId, role, expireTime) {
    // ATTENTION: Ceci est une version simplifiée
    // En production, utiliser: npm install agora-access-token
    // const { RtcTokenBuilder, RtcRole } = require('agora-access-token');
    return `agora-token-${channelName}-${userId}-${expireTime}`;
  }

  /**
   * Générer un token Twilio (à remplacer par SDK Twilio en production)
   * @private
   */
  _generateTwilioAccessToken(roomName, identity) {
    // ATTENTION: Ceci est une version simplifiée
    // En production, utiliser: npm install twilio
    // const twilio = require('twilio');
    // const AccessToken = twilio.jwt.AccessToken;
    return `twilio-token-${roomName}-${identity}`;
  }

  /**
   * Enregistrer une consultation (optionnel, avec consentement)
   * @param {string} sessionId - ID de la session
   * @param {Object} metadata - Métadonnées de la consultation
   * @returns {Promise<Object>} Résultat de l'enregistrement
   */
  async recordConsultation(sessionId, metadata = {}) {
    try {
      // En production, utiliser les APIs d'enregistrement Agora/Twilio
      return {
        success: true,
        sessionId: sessionId,
        recordingUrl: null, // URL de l'enregistrement si disponible
        metadata: metadata,
        message: 'Enregistrement démarré (configuration requise)'
      };
    } catch (error) {
      console.error('Erreur enregistrement:', error);
      throw error;
    }
  }
}

module.exports = new VideoConsultationService();

