const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const searchService = require('../services/search_service');

/**
 * Recherche avancée de diagnostics
 * POST /api/search/diagnostics
 */
router.post('/diagnostics', authenticateToken, async (req, res) => {
  try {
    const filters = req.body;
    const results = await searchService.searchDiagnostics(filters);
    res.json({
      results,
      count: results.length,
    });
  } catch (error) {
    console.error('Erreur recherche diagnostics:', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

/**
 * Recherche de patients
 * GET /api/search/patients?q=...
 */
router.get('/patients', authenticateToken, async (req, res) => {
  try {
    const query = req.query.q || '';
    const results = await searchService.searchPatients(query);
    res.json(results);
  } catch (error) {
    console.error('Erreur recherche patients:', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

/**
 * Sauvegarder un filtre de recherche
 * POST /api/search/filters
 */
router.post('/filters', authenticateToken, async (req, res) => {
  try {
    const { name, filters } = req.body;
    const userId = req.user.id;
    
    if (!name || !filters) {
      return res.status(400).json({ error: 'name et filters sont requis' });
    }
    
    await searchService.saveSearchFilter(userId, name, filters);
    res.status(201).json({ message: 'Filtre sauvegardé' });
  } catch (error) {
    console.error('Erreur sauvegarde filtre:', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

/**
 * Obtenir les filtres sauvegardés
 * GET /api/search/filters
 */
router.get('/filters', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;
    const filters = await searchService.getSavedFilters(userId);
    res.json(filters);
  } catch (error) {
    console.error('Erreur récupération filtres:', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

module.exports = router;
