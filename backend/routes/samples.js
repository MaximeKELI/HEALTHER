const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const { checkPermission, auditLog } = require('../middleware/permissions');
const { dbRun, dbGet, dbAll } = require('../config/database');
const Joi = require('joi');

const sampleSchema = Joi.object({
  diagnostic_id: Joi.number().integer().required(),
  barcode: Joi.string().optional(),
  sample_type: Joi.string().optional(),
  collection_date: Joi.string().optional(),
  lab_id: Joi.number().integer().optional(),
  metadata: Joi.object().optional()
});

// Créer un échantillon
router.post('/', authenticateToken, checkPermission('samples', 'create'), auditLog('create', 'samples'), async (req, res) => {
  try {
    const { error, value } = sampleSchema.validate(req.body);
    if (error) {
      return res.status(400).json({ error: error.details[0].message });
    }

    const { diagnostic_id, barcode, sample_type, collection_date, lab_id, metadata } = value;

    const result = await dbRun(
      `INSERT INTO samples (diagnostic_id, barcode, sample_type, collection_date, lab_id, metadata, status)
       VALUES (?, ?, ?, ?, ?, ?, 'pending')`,
      [
        diagnostic_id,
        barcode || null,
        sample_type || null,
        collection_date || null,
        lab_id || null,
        metadata ? JSON.stringify(metadata) : null
      ]
    );

    res.status(201).json({
      id: result.lastID,
      message: 'Échantillon créé avec succès'
    });
  } catch (error) {
    console.error('Erreur création échantillon:', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

// Obtenir un échantillon par code-barres
router.get('/barcode/:barcode', authenticateToken, checkPermission('samples', 'read'), async (req, res) => {
  try {
    const { barcode } = req.params;
    const sample = await dbGet('SELECT * FROM samples WHERE barcode = ?', [barcode]);
    
    if (!sample) {
      return res.status(404).json({ error: 'Échantillon non trouvé' });
    }

    res.json({
      ...sample,
      metadata: sample.metadata ? JSON.parse(sample.metadata) : null
    });
  } catch (error) {
    console.error('Erreur récupération échantillon:', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

// Mettre à jour le résultat labo
router.put('/:id/lab-result', authenticateToken, checkPermission('samples', 'update'), async (req, res) => {
  try {
    const { id } = req.params;
    const { lab_result, lab_result_date, status } = req.body;

    await dbRun(
      `UPDATE samples SET lab_result = ?, lab_result_date = ?, status = ?
       WHERE id = ?`,
      [lab_result || null, lab_result_date || null, status || 'completed', id]
    );

    res.json({ message: 'Résultat labo mis à jour' });
  } catch (error) {
    console.error('Erreur mise à jour labo:', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

// Obtenir tous les échantillons d'un diagnostic
router.get('/diagnostic/:diagnostic_id', authenticateToken, checkPermission('samples', 'read'), async (req, res) => {
  try {
    const { diagnostic_id } = req.params;
    const samples = await dbAll(
      'SELECT * FROM samples WHERE diagnostic_id = ? ORDER BY created_at DESC',
      [diagnostic_id]
    );

    res.json(samples.map(s => ({
      ...s,
      metadata: s.metadata ? JSON.parse(s.metadata) : null
    })));
  } catch (error) {
    console.error('Erreur récupération échantillons:', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

module.exports = router;

