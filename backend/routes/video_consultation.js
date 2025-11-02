const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const { checkPermission } = require('../middleware/permissions');
const videoConsultationService = require('../services/video_consultation_service');
const Joi = require('joi');

/**
 * Routes pour Vidéoconsultation / Télémédecine
 */

const consultationSessionSchema = Joi.object({
  consultationId: Joi.number().integer().required(),
  doctorId: Joi.number().integer().required(),
  patientId: Joi.number().integer().required(),
  provider: Joi.string().valid('agora', 'twilio', 'jitsi').optional()
});

// Créer une session de consultation vidéo
router.post('/session', authenticateToken, checkPermission('diagnostics', 'create'), async (req, res) => {
  try {
    const { error, value } = consultationSessionSchema.validate(req.body);

    if (error) {
      return res.status(400).json({
        success: false,
        error: error.details[0].message
      });
    }

    const { consultationId, doctorId, patientId, provider } = value;

    const session = await videoConsultationService.createConsultationSession(
      consultationId,
      doctorId,
      patientId,
      provider
    );

    res.json({
      success: true,
      session
    });
  } catch (error) {
    console.error('Erreur création session:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Générer un token Agora
router.post('/agora/token', authenticateToken, checkPermission('diagnostics', 'read'), async (req, res) => {
  try {
    const { channelName, userId, role, expireTime } = req.body;

    if (!channelName || userId === undefined) {
      return res.status(400).json({
        success: false,
        error: 'channelName et userId requis'
      });
    }

    const token = await videoConsultationService.generateAgoraToken(
      channelName,
      userId,
      role || 1,
      expireTime || 86400
    );

    res.json({
      success: true,
      ...token
    });
  } catch (error) {
    console.error('Erreur génération token Agora:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Générer un token Twilio Video
router.post('/twilio/token', authenticateToken, checkPermission('diagnostics', 'read'), async (req, res) => {
  try {
    const { roomName, identity } = req.body;

    if (!roomName || !identity) {
      return res.status(400).json({
        success: false,
        error: 'roomName et identity requis'
      });
    }

    const token = await videoConsultationService.generateTwilioToken(roomName, identity);

    res.json({
      success: true,
      ...token
    });
  } catch (error) {
    console.error('Erreur génération token Twilio:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Créer une session Jitsi (gratuite, pas de token nécessaire)
router.post('/jitsi/session', authenticateToken, checkPermission('diagnostics', 'read'), async (req, res) => {
  try {
    const { consultationId, doctorId, patientId } = req.body;

    if (!consultationId || !doctorId || !patientId) {
      return res.status(400).json({
        success: false,
        error: 'consultationId, doctorId et patientId requis'
      });
    }

    const channelName = `consultation-${consultationId}`;
    const session = {
      provider: 'jitsi',
      roomName: channelName,
      serverUrl: process.env.JITSI_SERVER_URL || 'https://meet.jit.si',
      roomUrl: `${process.env.JITSI_SERVER_URL || 'https://meet.jit.si'}/${channelName}`,
      doctor: { userId: doctorId },
      patient: { userId: patientId }
    };

    res.json({
      success: true,
      session
    });
  } catch (error) {
    console.error('Erreur création session Jitsi:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Enregistrer une consultation
router.post('/record', authenticateToken, checkPermission('diagnostics', 'create'), async (req, res) => {
  try {
    const { sessionId, metadata } = req.body;

    if (!sessionId) {
      return res.status(400).json({
        success: false,
        error: 'sessionId requis'
      });
    }

    const result = await videoConsultationService.recordConsultation(sessionId, metadata || {});

    res.json({
      success: true,
      ...result
    });
  } catch (error) {
    console.error('Erreur enregistrement:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

module.exports = router;

