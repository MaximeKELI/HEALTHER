const express = require('express');
const router = express.Router();
const { dbAll, dbGet } = require('../config/database');
const { authenticateToken } = require('../middleware/auth');
const { checkPermission } = require('../middleware/permissions');

// Statistiques générales pour le dashboard (protégé)
router.get('/stats', authenticateToken, checkPermission('dashboard', 'read'), async (req, res) => {
  try {
    const { region, date_debut, date_fin } = req.query;
    
    let whereClause = 'WHERE 1=1';
    const params = [];

    if (region) {
      whereClause += ' AND region = ?';
      params.push(region);
    }

    if (date_debut) {
      whereClause += ' AND DATE(created_at) >= ?';
      params.push(date_debut);
    }

    if (date_fin) {
      whereClause += ' AND DATE(created_at) <= ?';
      params.push(date_fin);
    }

    // Statistiques globales
    const totalCas = await dbGet(
      `SELECT COUNT(*) as total FROM diagnostics ${whereClause}`,
      params
    );

    const casPositifs = await dbGet(
      `SELECT COUNT(*) as total FROM diagnostics ${whereClause} AND statut = 'positif'`,
      params
    );

    const casNegatifs = await dbGet(
      `SELECT COUNT(*) as total FROM diagnostics ${whereClause} AND statut = 'negatif'`,
      params
    );

    // Par type de maladie
    const paludisme = await dbGet(
      `SELECT COUNT(*) as total, 
       SUM(CASE WHEN statut = 'positif' THEN 1 ELSE 0 END) as positifs
       FROM diagnostics ${whereClause} AND maladie_type = 'paludisme'`,
      params
    );

    const typhoide = await dbGet(
      `SELECT COUNT(*) as total, 
       SUM(CASE WHEN statut = 'positif' THEN 1 ELSE 0 END) as positifs
       FROM diagnostics ${whereClause} AND maladie_type = 'typhoide'`,
      params
    );

    // Statistiques par région
    const statsParRegion = await dbAll(
      `SELECT region, 
       COUNT(*) as total_cas,
       SUM(CASE WHEN statut = 'positif' THEN 1 ELSE 0 END) as cas_positifs,
       SUM(CASE WHEN statut = 'negatif' THEN 1 ELSE 0 END) as cas_negatifs
       FROM diagnostics ${whereClause}
       GROUP BY region
       ORDER BY total_cas DESC`,
      params
    );

    // Évolution sur les 30 derniers jours
    const evolution = await dbAll(
      `SELECT DATE(created_at) as date,
       COUNT(*) as total,
       SUM(CASE WHEN statut = 'positif' THEN 1 ELSE 0 END) as positifs
       FROM diagnostics ${whereClause}
       AND DATE(created_at) >= DATE('now', '-30 days')
       GROUP BY DATE(created_at)
       ORDER BY date ASC`,
      params
    );

    // Statistiques avancées - Comparaison régions
    const comparaisonRegions = await dbAll(
      `SELECT region,
       COUNT(*) as total_cas,
       SUM(CASE WHEN statut = 'positif' THEN 1 ELSE 0 END) as cas_positifs,
       SUM(CASE WHEN statut = 'negatif' THEN 1 ELSE 0 END) as cas_negatifs,
       AVG(confiance) as confiance_moyenne
       FROM diagnostics ${whereClause}
       GROUP BY region
       ORDER BY total_cas DESC
       LIMIT 10`,
      params
    );

    // Statistiques par centre de santé
    let sqlParCentre = `SELECT u.centre_sante,
       COUNT(*) as total_cas,
       SUM(CASE WHEN d.statut = 'positif' THEN 1 ELSE 0 END) as cas_positifs,
       SUM(CASE WHEN d.statut = 'negatif' THEN 1 ELSE 0 END) as cas_negatifs
       FROM diagnostics d
       JOIN users u ON d.user_id = u.id
       ${whereClause} AND u.centre_sante IS NOT NULL
       GROUP BY u.centre_sante
       ORDER BY total_cas DESC
       LIMIT 10`;
    const statsParCentre = await dbAll(sqlParCentre, params);

    res.json({
      global: {
        total: totalCas?.total || 0,
        positifs: casPositifs?.total || 0,
        negatifs: casNegatifs?.total || 0,
        taux_positivite: totalCas?.total > 0 
          ? ((casPositifs?.total || 0) / totalCas.total * 100).toFixed(2) 
          : 0
      },
      par_maladie: {
        paludisme: {
          total: paludisme?.total || 0,
          positifs: paludisme?.positifs || 0,
          taux_positivite: paludisme?.total > 0 
            ? ((paludisme.positifs / paludisme.total) * 100).toFixed(2) 
            : 0
        },
        typhoide: {
          total: typhoide?.total || 0,
          positifs: typhoide?.positifs || 0,
          taux_positivite: typhoide?.total > 0 
            ? ((typhoide.positifs / typhoide.total) * 100).toFixed(2) 
            : 0
        }
      },
      par_region: statsParRegion,
      comparaison_regions: comparaisonRegions,
      par_centre: statsParCentre,
      evolution: evolution
    });
  } catch (error) {
    console.error('Erreur lors de la récupération des statistiques:', error);
    res.status(500).json({ error: 'Erreur serveur lors de la récupération des statistiques' });
  }
});

// Clusters épidémiques actifs (protégé)
router.get('/epidemics', authenticateToken, checkPermission('dashboard', 'read'), async (req, res) => {
  try {
    const epidemics = await dbAll(
      `SELECT * FROM epidemics 
       WHERE statut = 'actif'
       ORDER BY nombre_cas DESC`
    );

    res.json(epidemics);
  } catch (error) {
    console.error('Erreur lors de la récupération des clusters:', error);
    res.status(500).json({ error: 'Erreur serveur lors de la récupération des clusters' });
  }
});

// Carte des cas (pour visualisation géographique) (protégé)
router.get('/map', authenticateToken, checkPermission('dashboard', 'read'), async (req, res) => {
  try {
    const { date_debut, date_fin } = req.query;
    
    let whereClause = 'WHERE latitude IS NOT NULL AND longitude IS NOT NULL';
    const params = [];

    if (date_debut) {
      whereClause += ' AND DATE(created_at) >= ?';
      params.push(date_debut);
    }

    if (date_fin) {
      whereClause += ' AND DATE(created_at) <= ?';
      params.push(date_fin);
    }

    const casLocalises = await dbAll(
      `SELECT id, latitude, longitude, maladie_type, statut, region, prefecture, created_at
       FROM diagnostics ${whereClause}
       ORDER BY created_at DESC
       LIMIT 1000`,
      params
    );

    res.json(casLocalises);
  } catch (error) {
    console.error('Erreur lors de la récupération de la carte:', error);
    res.status(500).json({ error: 'Erreur serveur lors de la récupération de la carte' });
  }
});

module.exports = router;


