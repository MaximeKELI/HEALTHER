const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const alertService = require('../services/alert_service');

/**
 * Vérifier les seuils et obtenir les alertes
 * GET /api/alerts/check
 */
router.get('/check', authenticateToken, async (req, res) => {
  try {
    const { region, maladieType, days } = req.query;

    const alerts = await alertService.checkThresholds({
      region: region || null,
      maladieType: maladieType || null,
      days: parseInt(days) || 7,
    });

    res.json({
      ...alerts,
      success: true,
    });
  } catch (error) {
    console.error('Erreur vérification alertes:', error);
    res.status(500).json({
      error: 'Erreur lors de la vérification',
      message: error.message,
    });
  }
});

/**
 * Configurer un seuil personnalisé
 * POST /api/alerts/threshold
 */
router.post('/threshold', authenticateToken, async (req, res) => {
  try {
    const { metric, warningLevel, criticalLevel, region, maladieType } = req.body;

    if (!metric || !warningLevel || !criticalLevel) {
      return res.status(400).json({ error: 'Paramètres requis manquants' });
    }

    const result = await alertService.setThreshold({
      metric,
      warningLevel,
      criticalLevel,
      region: region || null,
      maladieType: maladieType || null,
    });

    res.json({
      ...result,
      success: true,
    });
  } catch (error) {
    console.error('Erreur configuration seuil:', error);
    res.status(500).json({
      error: 'Erreur lors de la configuration',
      message: error.message,
    });
  }
});

/**
 * Obtenir l'historique des alertes
 * GET /api/alerts/history
 */
router.get('/history', authenticateToken, async (req, res) => {
  try {
    const { limit, offset } = req.query;

    const history = await alertService.getAlertHistory({
      limit: parseInt(limit) || 50,
      offset: parseInt(offset) || 0,
    });

    res.json({
      ...history,
      success: true,
    });
  } catch (error) {
    console.error('Erreur historique alertes:', error);
    res.status(500).json({
      error: 'Erreur lors de la récupération',
      message: error.message,
    });
  }
});

module.exports = router;

