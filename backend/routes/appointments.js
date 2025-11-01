const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const { checkPermission } = require('../middleware/permissions');
const { dbRun, dbGet, dbAll } = require('../config/database');
const Joi = require('joi');
const notificationService = require('../services/notification_service');

const appointmentSchema = Joi.object({
  diagnostic_id: Joi.number().integer().optional(),
  patient_name: Joi.string().optional(),
  patient_phone: Joi.string().optional(),
  appointment_date: Joi.string().required(),
  notes: Joi.string().optional()
});

// Créer un rendez-vous
router.post('/', authenticateToken, checkPermission('appointments', 'create'), async (req, res) => {
  try {
    const { error, value } = appointmentSchema.validate(req.body);
    if (error) {
      return res.status(400).json({ error: error.details[0].message });
    }

    const { diagnostic_id, patient_name, patient_phone, appointment_date, notes } = value;

    const result = await dbRun(
      `INSERT INTO appointments (diagnostic_id, patient_name, patient_phone, appointment_date, notes, created_by, status)
       VALUES (?, ?, ?, ?, ?, ?, 'scheduled')`,
      [
        diagnostic_id || null,
        patient_name || null,
        patient_phone || null,
        appointment_date,
        notes || null,
        req.user.id
      ]
    );

    // Envoyer notification SMS si numéro fourni (nécessite API-KEY)
    if (patient_phone) {
      const message = `Rappel: Vous avez un rendez-vous le ${appointment_date}`;
      await notificationService.sendSMS(patient_phone, message).catch(err => {
        console.error('Erreur envoi SMS:', err);
      });
    }

    res.status(201).json({
      id: result.lastID,
      message: 'Rendez-vous créé avec succès'
    });
  } catch (error) {
    console.error('Erreur création rendez-vous:', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

// Obtenir tous les rendez-vous
router.get('/', authenticateToken, checkPermission('appointments', 'read'), async (req, res) => {
  try {
    const { status, date_debut, date_fin } = req.query;
    
    let sql = 'SELECT * FROM appointments WHERE 1=1';
    const params = [];
    
    if (status) {
      sql += ' AND status = ?';
      params.push(status);
    }
    
    if (date_debut) {
      sql += ' AND DATE(appointment_date) >= ?';
      params.push(date_debut);
    }
    
    if (date_fin) {
      sql += ' AND DATE(appointment_date) <= ?';
      params.push(date_fin);
    }
    
    sql += ' ORDER BY appointment_date ASC';
    
    const appointments = await dbAll(sql, params);
    res.json(appointments);
  } catch (error) {
    console.error('Erreur récupération rendez-vous:', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

// Mettre à jour le statut d'un rendez-vous
router.put('/:id/status', authenticateToken, checkPermission('appointments', 'update'), async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;
    
    await dbRun(
      'UPDATE appointments SET status = ? WHERE id = ?',
      [status, id]
    );
    
    res.json({ message: 'Statut mis à jour' });
  } catch (error) {
    console.error('Erreur mise à jour rendez-vous:', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

module.exports = router;

