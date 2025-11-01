const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const { checkPermission } = require('../middleware/permissions');
const { dbRun, dbGet, dbAll } = require('../config/database');
const Joi = require('joi');

const healthCenterSchema = Joi.object({
  name: Joi.string().required(),
  type: Joi.string().optional(),
  latitude: Joi.number().optional(),
  longitude: Joi.number().optional(),
  address: Joi.string().optional(),
  region: Joi.string().optional(),
  prefecture: Joi.string().optional(),
  phone: Joi.string().optional(),
  email: Joi.string().email().optional(),
  resources: Joi.object().optional()
});

// Créer/mettre à jour un centre de santé
router.post('/', authenticateToken, checkPermission('health_centers', 'create'), async (req, res) => {
  try {
    const { error, value } = healthCenterSchema.validate(req.body);
    if (error) {
      return res.status(400).json({ error: error.details[0].message });
    }

    const result = await dbRun(
      `INSERT INTO health_centers (name, type, latitude, longitude, address, region, prefecture, phone, email, resources)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        value.name,
        value.type || null,
        value.latitude || null,
        value.longitude || null,
        value.address || null,
        value.region || null,
        value.prefecture || null,
        value.phone || null,
        value.email || null,
        value.resources ? JSON.stringify(value.resources) : null
      ]
    );

    res.status(201).json({
      id: result.lastID,
      message: 'Centre de santé créé avec succès'
    });
  } catch (error) {
    console.error('Erreur création centre:', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

// Obtenir tous les centres de santé
router.get('/', authenticateToken, checkPermission('health_centers', 'read'), async (req, res) => {
  try {
    const { region, type } = req.query;
    
    let sql = 'SELECT * FROM health_centers WHERE 1=1';
    const params = [];
    
    if (region) {
      sql += ' AND region = ?';
      params.push(region);
    }
    
    if (type) {
      sql += ' AND type = ?';
      params.push(type);
    }
    
    sql += ' ORDER BY name ASC';
    
    const centers = await dbAll(sql, params);
    
    res.json(centers.map(c => ({
      ...c,
      resources: c.resources ? JSON.parse(c.resources) : null
    })));
  } catch (error) {
    console.error('Erreur récupération centres:', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

module.exports = router;

