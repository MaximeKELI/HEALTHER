const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const { checkPermission } = require('../middleware/permissions');
const medicationService = require('../services/medication_service');
const Joi = require('joi');

/**
 * Routes pour Suivi Médication Avancé
 */

const medicationReminderSchema = Joi.object({
  medication_name: Joi.string().required(),
  dosage: Joi.string().optional(),
  frequency: Joi.string().valid('daily', 'weekly', 'as_needed').default('daily'),
  times_per_day: Joi.number().integer().min(1).default(1),
  start_date: Joi.string().isoDate().required(),
  end_date: Joi.string().isoDate().optional(),
  notes: Joi.string().optional(),
  interaction_check: Joi.boolean().default(false),
  other_medications: Joi.array().items(Joi.string()).optional()
});

// Rechercher un médicament dans OpenFDA
router.get('/search', authenticateToken, checkPermission('medications', 'read'), async (req, res) => {
  try {
    const { drugName } = req.query;

    if (!drugName) {
      return res.status(400).json({
        success: false,
        error: 'Nom du médicament requis'
      });
    }

    const result = await medicationService.searchDrugOpenFDA(drugName);

    res.json({
      success: result.success,
      ...result
    });
  } catch (error) {
    console.error('Erreur recherche médicament:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Normaliser le nom d'un médicament avec RxNorm
router.get('/normalize', authenticateToken, checkPermission('medications', 'read'), async (req, res) => {
  try {
    const { drugName } = req.query;

    if (!drugName) {
      return res.status(400).json({
        success: false,
        error: 'Nom du médicament requis'
      });
    }

    const result = await medicationService.normalizeDrugNameRxNorm(drugName);

    res.json({
      success: result.success,
      ...result
    });
  } catch (error) {
    console.error('Erreur normalisation médicament:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Vérifier les interactions médicamenteuses
router.post('/check-interactions', authenticateToken, checkPermission('medications', 'read'), async (req, res) => {
  try {
    const { drugNames } = req.body;

    if (!drugNames || !Array.isArray(drugNames) || drugNames.length < 2) {
      return res.status(400).json({
        success: false,
        error: 'Au moins 2 médicaments requis'
      });
    }

    const result = await medicationService.checkDrugInteractions(drugNames);

    res.json({
      success: result.success,
      ...result
    });
  } catch (error) {
    console.error('Erreur vérification interactions:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Créer un rappel de médicament
router.post('/reminders', authenticateToken, checkPermission('medications', 'create'), async (req, res) => {
  try {
    const { error, value } = medicationReminderSchema.validate(req.body);

    if (error) {
      return res.status(400).json({
        success: false,
        error: error.details[0].message
      });
    }

    const userId = req.user.id;
    const result = await medicationService.createMedicationReminder(userId, value);

    res.json({
      success: true,
      ...result
    });
  } catch (error) {
    console.error('Erreur création rappel:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Récupérer les rappels d'un utilisateur
router.get('/reminders', authenticateToken, checkPermission('medications', 'read'), async (req, res) => {
  try {
    const userId = req.user.id;
    const result = await medicationService.getUserMedicationReminders(userId);

    res.json({
      success: true,
      ...result
    });
  } catch (error) {
    console.error('Erreur récupération rappels:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Marquer une prise de médicament
router.post('/reminders/:id/taken', authenticateToken, checkPermission('medications', 'update'), async (req, res) => {
  try {
    const { id } = req.params;
    const { takenAt } = req.body;

    const result = await medicationService.markMedicationTaken(
      parseInt(id),
      takenAt || null
    );

    res.json({
      success: true,
      ...result
    });
  } catch (error) {
    console.error('Erreur marquage médicament:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Obtenir les statistiques d'observance
router.get('/adherence', authenticateToken, checkPermission('medications', 'read'), async (req, res) => {
  try {
    const userId = req.user.id;
    const { startDate, endDate } = req.query;

    const result = await medicationService.getAdherenceStatistics(
      userId,
      startDate || null,
      endDate || null
    );

    res.json({
      success: true,
      ...result
    });
  } catch (error) {
    console.error('Erreur statistiques observance:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

module.exports = router;

