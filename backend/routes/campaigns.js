const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const { checkPermission, auditLog } = require('../middleware/permissions');
const { dbRun, dbGet, dbAll } = require('../config/database');
const Joi = require('joi');

const campaignSchema = Joi.object({
  name: Joi.string().required(),
  type: Joi.string().valid('spraying', 'awareness', 'vaccination', 'screening').required(),
  region: Joi.string().optional(),
  start_date: Joi.string().optional(),
  end_date: Joi.string().optional(),
  description: Joi.string().optional(),
  resources_needed: Joi.object().optional(),
  status: Joi.string().valid('planned', 'active', 'completed', 'cancelled').default('planned')
});

// Créer une campagne
router.post('/', authenticateToken, checkPermission('campaigns', 'create'), auditLog('create', 'campaigns'), async (req, res) => {
  try {
    const { error, value } = campaignSchema.validate(req.body);
    if (error) {
      return res.status(400).json({ error: error.details[0].message });
    }

    const result = await dbRun(
      `INSERT INTO campaigns (name, type, region, start_date, end_date, description, resources_needed, status, created_by)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        value.name,
        value.type,
        value.region || null,
        value.start_date || null,
        value.end_date || null,
        value.description || null,
        value.resources_needed ? JSON.stringify(value.resources_needed) : null,
        value.status,
        req.user.id
      ]
    );

    res.status(201).json({
      id: result.lastID,
      message: 'Campagne créée avec succès'
    });
  } catch (error) {
    console.error('Erreur création campagne:', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

// Obtenir toutes les campagnes
router.get('/', authenticateToken, checkPermission('campaigns', 'read'), async (req, res) => {
  try {
    const { status, region, type } = req.query;
    
    let sql = 'SELECT * FROM campaigns WHERE 1=1';
    const params = [];
    
    if (status) {
      sql += ' AND status = ?';
      params.push(status);
    }
    
    if (region) {
      sql += ' AND region = ?';
      params.push(region);
    }
    
    if (type) {
      sql += ' AND type = ?';
      params.push(type);
    }
    
    sql += ' ORDER BY created_at DESC';
    
    const campaigns = await dbAll(sql, params);
    
    res.json(campaigns.map(c => ({
      ...c,
      resources_needed: c.resources_needed ? JSON.parse(c.resources_needed) : null
    })));
  } catch (error) {
    console.error('Erreur récupération campagnes:', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

module.exports = router;

