const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const totpService = require('../services/totp_service');

/**
 * Générer un secret TOTP et QR code
 * POST /api/totp/generate
 */
router.post('/generate', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;
    const username = req.user.username;
    
    const result = await totpService.generateTOTPSecret(userId, username);
    
    res.json({
      secret: result.secret,
      qrCodeUrl: result.qrCodeUrl,
      backupCodes: result.backupCodes,
      message: 'Secret TOTP généré. Utilisez le QR code pour configurer votre application 2FA.',
    });
  } catch (error) {
    console.error('Erreur génération TOTP:', error);
    res.status(500).json({ error: 'Erreur lors de la génération du secret TOTP' });
  }
});

/**
 * Activer 2FA
 * POST /api/totp/enable
 */
router.post('/enable', authenticateToken, async (req, res) => {
  try {
    const { token } = req.body;
    const userId = req.user.id;
    
    if (!token) {
      return res.status(400).json({ error: 'Code TOTP requis' });
    }
    
    const enabled = await totpService.enable2FA(userId, token);
    
    if (enabled) {
      res.json({ message: '2FA activé avec succès' });
    } else {
      res.status(400).json({ error: 'Code TOTP invalide' });
    }
  } catch (error) {
    console.error('Erreur activation 2FA:', error);
    res.status(500).json({ error: 'Erreur lors de l\'activation de 2FA' });
  }
});

/**
 * Désactiver 2FA
 * POST /api/totp/disable
 */
router.post('/disable', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;
    await totpService.disable2FA(userId);
    res.json({ message: '2FA désactivé avec succès' });
  } catch (error) {
    console.error('Erreur désactivation 2FA:', error);
    res.status(500).json({ error: 'Erreur lors de la désactivation de 2FA' });
  }
});

module.exports = router;
