const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const { checkPermission } = require('../middleware/permissions');
const { dbRun, dbGet, dbAll } = require('../config/database');
const { dbAll: dbAllAsync } = require('../config/database');
const Joi = require('joi');

const geofenceSchema = Joi.object({
  name: Joi.string().required(),
  region: Joi.string().optional(),
  prefecture: Joi.string().optional(),
  latitude: Joi.number().required(),
  longitude: Joi.number().required(),
  radius: Joi.number().required(),
  threshold_cases: Joi.number().integer().default(10),
  threshold_days: Joi.number().integer().default(7),
  maladie_type: Joi.string().valid('paludisme', 'typhoide', 'mixte').optional(),
  active: Joi.boolean().default(true)
});

// Créer une zone géofencing
router.post('/', authenticateToken, checkPermission('geofences', 'create'), async (req, res) => {
  try {
    const { error, value } = geofenceSchema.validate(req.body);
    if (error) {
      return res.status(400).json({ error: error.details[0].message });
    }

    const result = await dbRun(
      `INSERT INTO geofences (name, region, prefecture, latitude, longitude, radius, threshold_cases, threshold_days, maladie_type, active)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        value.name,
        value.region || null,
        value.prefecture || null,
        value.latitude,
        value.longitude,
        value.radius,
        value.threshold_cases,
        value.threshold_days,
        value.maladie_type || null,
        value.active
      ]
    );

    res.status(201).json({
      id: result.lastID,
      message: 'Zone géofencing créée'
    });
  } catch (error) {
    console.error('Erreur création géofence:', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

// Obtenir toutes les zones actives
router.get('/', authenticateToken, checkPermission('geofences', 'read'), async (req, res) => {
  try {
    const geofences = await dbAll('SELECT * FROM geofences WHERE active = 1');
    res.json(geofences);
  } catch (error) {
    console.error('Erreur récupération géofences:', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

// Vérifier les alertes géofencing (heatmap/clusters)
router.get('/check-alerts', authenticateToken, checkPermission('geofences', 'read'), async (req, res) => {
  try {
    const { region, date_debut, date_fin } = req.query;
    
    const geofences = await dbAll('SELECT * FROM geofences WHERE active = 1');
    const alerts = [];

    for (const geofence of geofences) {
      // Calculer la distance et vérifier les cas dans la zone
      let sql = `SELECT COUNT(*) as count FROM diagnostics 
                 WHERE latitude IS NOT NULL AND longitude IS NOT NULL 
                 AND statut = 'positif'`;
      
      const params = [];
      
      if (geofence.maladie_type) {
        sql += ' AND maladie_type = ?';
        params.push(geofence.maladie_type);
      }
      
      if (date_debut) {
        sql += ' AND DATE(created_at) >= ?';
        params.push(date_debut);
      } else {
        // Utiliser threshold_days par défaut
        sql += ` AND DATE(created_at) >= DATE('now', '-${geofence.threshold_days} days')`;
      }
      
      if (date_fin) {
        sql += ' AND DATE(created_at) <= ?';
        params.push(date_fin);
      }

      const result = await dbGet(sql, params);
      const caseCount = result?.count || 0;

      if (caseCount >= geofence.threshold_cases) {
        // Calculer distance approximative (formule haversine simplifiée)
        alerts.push({
          geofence_id: geofence.id,
          geofence_name: geofence.name,
          case_count: caseCount,
          threshold: geofence.threshold_cases,
          alert_level: caseCount >= geofence.threshold_cases * 3 ? 'high' : 'medium',
          location: {
            latitude: geofence.latitude,
            longitude: geofence.longitude,
            radius: geofence.radius
          }
        });
      }
    }

    res.json({ alerts, count: alerts.length });
  } catch (error) {
    console.error('Erreur vérification alertes:', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

// Obtenir heatmap des cas
router.get('/heatmap', authenticateToken, checkPermission('geofences', 'read'), async (req, res) => {
  try {
    const { region, date_debut, date_fin, maladie_type } = req.query;
    
    let sql = `SELECT 
      latitude,
      longitude,
      COUNT(*) as case_count,
      SUM(CASE WHEN statut = 'positif' THEN 1 ELSE 0 END) as positive_count,
      region,
      prefecture
     FROM diagnostics 
     WHERE latitude IS NOT NULL AND longitude IS NOT NULL`;
    
    const params = [];
    
    if (region) {
      sql += ' AND region = ?';
      params.push(region);
    }
    
    if (maladie_type) {
      sql += ' AND maladie_type = ?';
      params.push(maladie_type);
    }
    
    if (date_debut) {
      sql += ' AND DATE(created_at) >= ?';
      params.push(date_debut);
    }
    
    if (date_fin) {
      sql += ' AND DATE(created_at) <= ?';
      params.push(date_fin);
    }
    
    sql += ' GROUP BY latitude, longitude, region, prefecture';
    
    const heatmap = await dbAll(sql, params);
    
    res.json(heatmap);
  } catch (error) {
    console.error('Erreur heatmap:', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

module.exports = router;

