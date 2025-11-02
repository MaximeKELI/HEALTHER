const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const { checkPermission } = require('../middleware/permissions');
const contactTracingService = require('../services/contact_tracing_service');

/**
 * Routes pour Contact Tracing / Investigation d'Épidémie
 */

// Trouver les contacts d'un diagnostic
router.get('/diagnostic/:id/contacts', 
  authenticateToken, 
  checkPermission('diagnostics', 'read'),
  async (req, res) => {
    try {
      const { id } = req.params;
      const contacts = await contactTracingService.findContacts(parseInt(id));
      
      res.json({
        success: true,
        diagnostic_id: parseInt(id),
        contacts_count: contacts.length,
        contacts
      });
    } catch (error) {
      console.error('Erreur récupération contacts:', error);
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  }
);

// Construire le graphique de transmission
router.get('/patient/:id/transmission-graph',
  authenticateToken,
  checkPermission('diagnostics', 'read'),
  async (req, res) => {
    try {
      const { id } = req.params;
      const maxDepth = parseInt(req.query.maxDepth) || 5;
      
      const graph = await contactTracingService.buildTransmissionGraph(
        parseInt(id),
        maxDepth
      );
      
      res.json({
        success: true,
        patient_id: parseInt(id),
        graph
      });
    } catch (error) {
      console.error('Erreur construction graphe:', error);
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  }
);

// Calculer le R0 (taux de reproduction)
router.get('/r0',
  authenticateToken,
  checkPermission('diagnostics', 'read'),
  async (req, res) => {
    try {
      const { region, startDate, endDate } = req.query;
      
      const R0Stats = await contactTracingService.calculateR0(
        region || null,
        startDate || null,
        endDate || null
      );
      
      res.json({
        success: true,
        ...R0Stats
      });
    } catch (error) {
      console.error('Erreur calcul R0:', error);
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  }
);

// Générer rapport d'investigation
router.get('/diagnostic/:id/investigation-report',
  authenticateToken,
  checkPermission('diagnostics', 'read'),
  async (req, res) => {
    try {
      const { id } = req.params;
      
      const report = await contactTracingService.generateInvestigationReport(
        parseInt(id)
      );
      
      res.json({
        success: true,
        report
      });
    } catch (error) {
      console.error('Erreur génération rapport:', error);
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  }
);

module.exports = router;

