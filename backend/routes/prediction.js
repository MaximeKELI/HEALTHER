const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const predictionService = require('../services/prediction_service');

/**
 * Prédire les épidémies futures
 * GET /api/prediction/epidemics
 */
router.get('/epidemics', authenticateToken, async (req, res) => {
  try {
    const { region, maladieType, daysAhead, includeHistory } = req.query;

    const predictions = await predictionService.predictEpidemics({
      region: region || null,
      maladieType: maladieType || null,
      daysAhead: parseInt(daysAhead) || 7,
      includeHistory: includeHistory === 'true',
    });

    res.json({
      ...predictions,
      success: true,
    });
  } catch (error) {
    console.error('Erreur prédiction épidémique:', error);
    res.status(500).json({
      error: 'Erreur lors de la prédiction',
      message: error.message,
    });
  }
});

/**
 * Détecter les anomalies dans les données
 * GET /api/prediction/anomalies
 */
router.get('/anomalies', authenticateToken, async (req, res) => {
  try {
    const { region, maladieType, days } = req.query;

    const anomalies = await predictionService.detectAnomalies({
      region: region || null,
      maladieType: maladieType || null,
      days: parseInt(days) || 7,
    });

    res.json({
      ...anomalies,
      success: true,
    });
  } catch (error) {
    console.error('Erreur détection anomalies:', error);
    res.status(500).json({
      error: 'Erreur lors de la détection',
      message: error.message,
    });
  }
});

module.exports = router;

