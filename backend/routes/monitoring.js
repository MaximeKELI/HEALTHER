const express = require('express');
const router = express.Router();
const monitoringService = require('../services/monitoring_service');
const anomalyDetectionService = require('../services/anomaly_detection_service');
const { authenticateToken } = require('../middleware/auth');
const { checkPermission } = require('../middleware/permissions');

/**
 * Endpoint Prometheus metrics
 * GET /metrics
 */
router.get('/metrics', async (req, res) => {
  try {
    const register = monitoringService.register;
    res.set('Content-Type', register.contentType);
    res.end(await monitoringService.getMetrics());
  } catch (error) {
    res.status(500).end(error);
  }
});

/**
 * Obtenir les anomalies détectées
 * GET /api/monitoring/anomalies
 */
router.get('/anomalies', authenticateToken, async (req, res) => {
  try {
    // Vérifier permissions (admin ou supervisor)
    if (!['admin', 'supervisor'].includes(req.user.role)) {
      return res.status(403).json({ error: 'Permission refusée' });
    }
    
    const anomalies = await anomalyDetectionService.detectAnomalies();
    const patterns = await anomalyDetectionService.detectSuspiciousPatterns();
    
    res.json({
      anomalies,
      patterns,
      total: anomalies.length + patterns.length,
    });
  } catch (error) {
    console.error('Erreur détection anomalies:', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

module.exports = router;
