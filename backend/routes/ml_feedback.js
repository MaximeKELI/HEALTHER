const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const { checkPermission, auditLog } = require('../middleware/permissions');
const { dbRun, dbGet, dbAll } = require('../config/database');
const Joi = require('joi');

const feedbackSchema = Joi.object({
  diagnostic_id: Joi.number().integer().required(),
  predicted_result: Joi.boolean().optional(),
  actual_result: Joi.boolean().required(),
  confidence: Joi.number().min(0).max(100).optional(),
  feedback_type: Joi.string().valid('correct', 'incorrect', 'uncertain').required(),
  comments: Joi.string().optional()
});

// Soumettre un feedback ML
router.post('/', authenticateToken, checkPermission('ml_feedback', 'create'), auditLog('create', 'ml_feedback'), async (req, res) => {
  try {
    const { error, value } = feedbackSchema.validate(req.body);
    if (error) {
      return res.status(400).json({ error: error.details[0].message });
    }

    const { diagnostic_id, predicted_result, actual_result, confidence, feedback_type, comments } = value;

    // Récupérer le résultat prédit du diagnostic
    const diagnostic = await dbGet('SELECT resultat_ia, confiance FROM diagnostics WHERE id = ?', [diagnostic_id]);
    if (!diagnostic) {
      return res.status(404).json({ error: 'Diagnostic non trouvé' });
    }

    const resultatIa = diagnostic.resultat_ia ? JSON.parse(diagnostic.resultat_ia) : null;
    const predicted = predicted_result !== undefined ? predicted_result : (resultatIa?.detected || false);
    const conf = confidence || diagnostic.confiance || null;

    const result = await dbRun(
      `INSERT INTO ml_feedback (diagnostic_id, user_id, predicted_result, actual_result, confidence, feedback_type, comments)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [diagnostic_id, req.user.id, predicted, actual_result, conf, feedback_type, comments || null]
    );

    res.status(201).json({
      id: result.lastID,
      message: 'Feedback enregistré avec succès'
    });
  } catch (error) {
    console.error('Erreur création feedback:', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

// Obtenir les statistiques de feedback ML
router.get('/stats', authenticateToken, checkPermission('ml_feedback', 'read'), async (req, res) => {
  try {
    const stats = await dbGet(
      `SELECT 
        COUNT(*) as total,
        SUM(CASE WHEN feedback_type = 'correct' THEN 1 ELSE 0 END) as correct,
        SUM(CASE WHEN feedback_type = 'incorrect' THEN 1 ELSE 0 END) as incorrect,
        SUM(CASE WHEN feedback_type = 'uncertain' THEN 1 ELSE 0 END) as uncertain,
        AVG(confidence) as avg_confidence
       FROM ml_feedback`
    );

    res.json({
      total: stats.total || 0,
      correct: stats.correct || 0,
      incorrect: stats.incorrect || 0,
      uncertain: stats.uncertain || 0,
      accuracy: stats.total > 0 ? ((stats.correct || 0) / stats.total * 100).toFixed(2) : 0,
      avg_confidence: stats.avg_confidence || 0
    });
  } catch (error) {
    console.error('Erreur stats feedback:', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

module.exports = router;

