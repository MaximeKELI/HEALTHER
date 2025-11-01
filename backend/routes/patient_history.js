const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const patientHistoryService = require('../services/patient_history_service');

/**
 * Obtenir l'historique d'un patient
 * GET /api/patient-history/:identifier
 */
router.get('/:identifier', authenticateToken, async (req, res) => {
  try {
    const { identifier } = req.params;
    const history = await patientHistoryService.getPatientHistory(identifier);
    res.json(history);
  } catch (error) {
    console.error('Erreur récupération historique patient:', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

/**
 * Obtenir le profil patient consolidé
 * GET /api/patient-history/:identifier/profile
 */
router.get('/:identifier/profile', authenticateToken, async (req, res) => {
  try {
    const { identifier } = req.params;
    const profile = await patientHistoryService.getPatientProfile(identifier);
    res.json(profile);
  } catch (error) {
    console.error('Erreur récupération profil patient:', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

/**
 * Ajouter un événement à l'historique
 * POST /api/patient-history
 */
router.post('/', authenticateToken, async (req, res) => {
  try {
    const { patient_identifier, diagnostic_id, event_type, details } = req.body;
    
    if (!patient_identifier || !event_type) {
      return res.status(400).json({ error: 'patient_identifier et event_type sont requis' });
    }
    
    await patientHistoryService.addPatientEvent(
      patient_identifier,
      diagnostic_id || null,
      event_type,
      details || {}
    );
    
    res.status(201).json({ message: 'Événement ajouté à l\'historique' });
  } catch (error) {
    console.error('Erreur ajout événement historique:', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

module.exports = router;
