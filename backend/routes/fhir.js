const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const fhirService = require('../services/fhir_service');
const { dbGet } = require('../config/database');

/**
 * Convertir un diagnostic en Observation FHIR
 * GET /api/fhir/diagnostic/:id/observation
 */
router.get('/diagnostic/:id/observation', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const diagnostic = await dbGet('SELECT * FROM diagnostics WHERE id = ?', [id]);
    
    if (!diagnostic) {
      return res.status(404).json({ error: 'Diagnostic non trouvé' });
    }
    
    const observation = fhirService.diagnosticToFHIR(diagnostic);
    res.json(observation);
  } catch (error) {
    console.error('Erreur conversion FHIR:', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

/**
 * Envoyer un diagnostic à un endpoint FHIR
 * POST /api/fhir/diagnostic/:id/send
 */
router.post('/diagnostic/:id/send', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const { endpoint, api_key } = req.body;
    
    if (!endpoint) {
      return res.status(400).json({ error: 'endpoint est requis' });
    }
    
    const diagnostic = await dbGet('SELECT * FROM diagnostics WHERE id = ?', [id]);
    
    if (!diagnostic) {
      return res.status(404).json({ error: 'Diagnostic non trouvé' });
    }
    
    const observation = fhirService.diagnosticToFHIR(diagnostic);
    const result = await fhirService.sendFHIRObservation(endpoint, observation, api_key);
    
    res.json({
      message: 'Observation FHIR envoyée avec succès',
      result,
    });
  } catch (error) {
    console.error('Erreur envoi FHIR:', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

module.exports = router;
