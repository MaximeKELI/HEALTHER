const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const { checkPermission, auditLog } = require('../middleware/permissions');
const { dbRun, dbGet, dbAll } = require('../config/database');
const Joi = require('joi');
const fs = require('fs');
const path = require('path');

const reportSchema = Joi.object({
  type: Joi.string().valid('weekly', 'monthly', 'custom').required(),
  region: Joi.string().optional(),
  date_start: Joi.string().optional(),
  date_end: Joi.string().optional(),
  parameters: Joi.object().optional()
});

// Générer un rapport
router.post('/generate', authenticateToken, checkPermission('reports', 'create'), auditLog('create', 'reports'), async (req, res) => {
  try {
    const { error, value } = reportSchema.validate(req.body);
    if (error) {
      return res.status(400).json({ error: error.details[0].message });
    }

    const { type, region, date_start, date_end, parameters } = value;

    // Générer le rapport (CSV pour l'instant - facile à implémenter)
    let sql = `SELECT 
      DATE(created_at) as date,
      region,
      maladie_type,
      COUNT(*) as total_cas,
      SUM(CASE WHEN statut = 'positif' THEN 1 ELSE 0 END) as cas_positifs,
      SUM(CASE WHEN statut = 'negatif' THEN 1 ELSE 0 END) as cas_negatifs
     FROM diagnostics WHERE 1=1`;
    
    const params = [];
    
    if (region) {
      sql += ' AND region = ?';
      params.push(region);
    }
    
    if (date_start) {
      sql += ' AND DATE(created_at) >= ?';
      params.push(date_start);
    }
    
    if (date_end) {
      sql += ' AND DATE(created_at) <= ?';
      params.push(date_end);
    }
    
    sql += ' GROUP BY DATE(created_at), region, maladie_type ORDER BY date DESC';
    
    const data = await dbAll(sql, params);
    
    // Générer CSV
    let csv = 'Date,Région,Type Maladie,Cas Totaux,Cas Positifs,Cas Négatifs,Taux Positivité\n';
    data.forEach(row => {
      const taux = row.total_cas > 0 ? ((row.cas_positifs / row.total_cas) * 100).toFixed(2) : 0;
      csv += `${row.date},${row.region || ''},${row.maladie_type},${row.total_cas},${row.cas_positifs},${row.cas_negatifs},${taux}%\n`;
    });
    
    // Sauvegarder le fichier
    const reportsDir = path.join(__dirname, '..', 'reports');
    if (!fs.existsSync(reportsDir)) {
      fs.mkdirSync(reportsDir, { recursive: true });
    }
    
    const filename = `report_${type}_${Date.now()}.csv`;
    const filepath = path.join(reportsDir, filename);
    fs.writeFileSync(filepath, csv, 'utf8');
    
    // Enregistrer dans la DB
    const result = await dbRun(
      `INSERT INTO reports (type, region, date_start, date_end, generated_by, file_path, parameters)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [
        type,
        region || null,
        date_start || null,
        date_end || null,
        req.user.id,
        filename,
        parameters ? JSON.stringify(parameters) : null
      ]
    );

    res.status(201).json({
      id: result.lastID,
      file_path: filename,
      message: 'Rapport généré avec succès'
    });
  } catch (error) {
    console.error('Erreur génération rapport:', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

// Télécharger un rapport
router.get('/:id/download', authenticateToken, checkPermission('reports', 'read'), async (req, res) => {
  try {
    const { id } = req.params;
    const report = await dbGet('SELECT * FROM reports WHERE id = ?', [id]);
    
    if (!report) {
      return res.status(404).json({ error: 'Rapport non trouvé' });
    }
    
    const filepath = path.join(__dirname, '..', 'reports', report.file_path);
    
    if (!fs.existsSync(filepath)) {
      return res.status(404).json({ error: 'Fichier non trouvé' });
    }
    
    res.download(filepath, report.file_path);
  } catch (error) {
    console.error('Erreur téléchargement rapport:', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

// Obtenir tous les rapports
router.get('/', authenticateToken, checkPermission('reports', 'read'), async (req, res) => {
  try {
    const reports = await dbAll(
      'SELECT * FROM reports ORDER BY created_at DESC LIMIT 50'
    );
    
    res.json(reports.map(r => ({
      ...r,
      parameters: r.parameters ? JSON.parse(r.parameters) : null
    })));
  } catch (error) {
    console.error('Erreur récupération rapports:', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

module.exports = router;

