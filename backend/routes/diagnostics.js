const express = require('express');
const router = express.Router();
const { dbRun, dbGet, dbAll } = require('../config/database');
const { authenticateToken } = require('../middleware/auth');
const Joi = require('joi');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const storageService = require('../services/storage_service');
const imageQualityService = require('../services/image_quality_service');

// Multer storage configuration
const uploadsDir = path.join(__dirname, '..', 'uploads');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, uploadsDir);
  },
  filename: function (req, file, cb) {
    const unique = Date.now() + '-' + Math.round(Math.random() * 1e9);
    const ext = path.extname(file.originalname) || '.jpg';
    cb(null, unique + ext);
  }
});
const upload = multer({
  storage,
  limits: { fileSize: 10 * 1024 * 1024 }, // 10MB
  fileFilter: (req, file, cb) => {
    const allowed = ['image/jpeg', 'image/png', 'image/jpg'];
    if (allowed.includes(file.mimetype)) return cb(null, true);
    cb(new Error('Type de fichier non supporté'));
  }
});

// Joi schemas
const diagnosticSchema = Joi.object({
  user_id: Joi.number().integer().required(),
  maladie_type: Joi.string().valid('paludisme', 'typhoide', 'mixte').required(),
  image_base64: Joi.string().base64({ paddingRequired: false }).optional(),
  resultat_ia: Joi.object().unknown(true).optional(),
  confiance: Joi.number().min(0).max(100).optional(),
  statut: Joi.string().valid('positif', 'negatif', 'incertain').required(),
  quantite_parasites: Joi.number().min(0).optional(),
  commentaires: Joi.string().max(2000).allow(null, '').optional(),
  latitude: Joi.number().optional(),
  longitude: Joi.number().optional(),
  adresse: Joi.string().allow(null, '').optional(),
  region: Joi.string().allow(null, '').optional(),
  prefecture: Joi.string().allow(null, '').optional()
});

// Créer un nouveau diagnostic (protégé par JWT)
router.post('/', authenticateToken, async (req, res) => {
  try {
    const {
      user_id,
      maladie_type,
      image_base64,
      resultat_ia,
      confiance,
      statut,
      quantite_parasites,
      commentaires,
      latitude,
      longitude,
      adresse,
      region,
      prefecture
    } = req.body;

    // Utiliser user_id du token JWT si disponible
    const userIdFromToken = req.user?.id;
    const finalUserId = userIdFromToken || parseInt(user_id);
    
    const bodyForValidation = { ...req.body, user_id: finalUserId };
    const { error } = diagnosticSchema.validate(bodyForValidation);
    if (error) {
      return res.status(400).json({ error: error.details[0].message });
    }

    const sql = `INSERT INTO diagnostics (
      user_id, maladie_type, image_base64, resultat_ia, confiance,
      statut, quantite_parasites, commentaires, latitude, longitude,
      adresse, region, prefecture
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`;

    const result = await dbRun(sql, [
      finalUserId,
      maladie_type,
      image_base64 || null,
      JSON.stringify(resultat_ia) || null,
      confiance || null,
      statut,
      quantite_parasites || null,
      commentaires || null,
      latitude || null,
      longitude || null,
      adresse || null,
      region || null,
      prefecture || null
    ]);

    // Mettre à jour les statistiques quotidiennes
    await updateDailyStats(maladie_type, statut, region);

    // Vérifier les clusters épidémiques et notifier si nécessaire
    const clusterDetected = await checkEpidemicClusters(region, prefecture, maladie_type, req.io);

    // Ajouter à l'historique patient si identifiant fourni
    if (req.body.patient_identifier) {
      const patientHistoryService = require('../services/patient_history_service');
      await patientHistoryService.addPatientEvent(
        req.body.patient_identifier,
        result.lastID,
        'diagnostic',
        {
          maladie_type,
          statut,
          confiance,
          region,
          prefecture,
        }
      );
    }

    res.status(201).json({
      id: result.lastID,
      message: 'Diagnostic créé avec succès'
    });
  } catch (error) {
    console.error('Erreur lors de la création du diagnostic:', error);
    res.status(500).json({ error: 'Erreur serveur lors de la création du diagnostic' });
  }
});

// Nouvelle route: création via upload de fichier image (multipart/form-data, protégée par JWT)
// champ fichier: image_file; autres champs texte: user_id, maladie_type, ...
router.post('/upload', authenticateToken, upload.single('image_file'), async (req, res) => {
  try {
    const body = req.body || {};
    // Utiliser user_id du token JWT si fourni, sinon celui du body
    const userIdFromToken = req.user?.id;
    const {
      user_id,
      maladie_type,
      resultat_ia,
      confiance,
      statut,
      quantite_parasites,
      commentaires,
      latitude,
      longitude,
      adresse,
      region,
      prefecture
    } = body;
    
    // Priorité au user_id du token JWT
    const finalUserId = userIdFromToken || parseInt(user_id);

    // Valider le body (sans image_base64 ici)
    const { error } = diagnosticSchema.fork(['image_base64'], (s) => s.forbidden()).validate(body);
    if (error) {
      return res.status(400).json({ error: error.details[0].message });
    }

    // Vérifier le fichier
    if (!req.file) {
      return res.status(400).json({ error: 'image_file est requis' });
    }

    // Lire le buffer du fichier
    const fileBuffer = fs.readFileSync(req.file.path);
    
    // Analyser la qualité de l'image
    const qualityMetrics = await imageQualityService.analyzeImageQuality(fileBuffer);
    
    // Upload vers S3/MinIO ou stockage local
    const storedKey = await storageService.uploadFile(
      fileBuffer,
      req.file.originalname,
      req.file.mimetype
    );
    
    // Supprimer le fichier local temporaire
    fs.unlinkSync(req.file.path);
    
    // Générer URL signée (valide 1h)
    const signedUrl = await storageService.getSignedUrl(storedKey, 3600);

    const sql = `INSERT INTO diagnostics (
      user_id, maladie_type, image_path, resultat_ia, confiance,
      statut, quantite_parasites, commentaires, latitude, longitude,
      adresse, region, prefecture, image_quality_metrics
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`;

    const result = await dbRun(sql, [
      finalUserId,
      maladie_type,
      storedKey,
      resultat_ia ? JSON.stringify(resultat_ia) : null,
      confiance || null,
      statut,
      quantite_parasites || null,
      commentaires || null,
      latitude || null,
      longitude || null,
      adresse || null,
      region || null,
      prefecture || null,
      qualityMetrics ? JSON.stringify(qualityMetrics) : null
    ]);

    await updateDailyStats(maladie_type, statut, region);
    await checkEpidemicClusters(region, prefecture, maladie_type, req.io);

    // Ajouter à l'historique patient si identifiant fourni
    if (body.patient_identifier) {
      const patientHistoryService = require('../services/patient_history_service');
      await patientHistoryService.addPatientEvent(
        body.patient_identifier,
        result.lastID,
        'diagnostic',
        {
          maladie_type,
          statut,
          confiance,
          region,
          prefecture,
          quality_score: qualityMetrics?.quality_score,
        }
      );
    }

    res.status(201).json({
      id: result.lastID,
      image_path: storedKey,
      image_url: signedUrl,
      quality_metrics: qualityMetrics,
      message: 'Diagnostic créé avec succès (upload)'
    });
  } catch (error) {
    console.error('Erreur lors de la création du diagnostic (upload):', error);
    res.status(500).json({ error: 'Erreur serveur lors de la création du diagnostic (upload)' });
  }
});

// Obtenir tous les diagnostics
router.get('/', async (req, res) => {
  try {
    const { user_id, maladie_type, region, date_debut, date_fin, limit = 100 } = req.query;
    
    let sql = 'SELECT * FROM diagnostics WHERE 1=1';
    const params = [];

    if (user_id) {
      sql += ' AND user_id = ?';
      params.push(user_id);
    }

    if (maladie_type) {
      sql += ' AND maladie_type = ?';
      params.push(maladie_type);
    }

    if (region) {
      sql += ' AND region = ?';
      params.push(region);
    }

    if (date_debut) {
      sql += ' AND DATE(created_at) >= ?';
      params.push(date_debut);
    }

    if (date_fin) {
      sql += ' AND DATE(created_at) <= ?';
      params.push(date_fin);
    }

    sql += ' ORDER BY created_at DESC LIMIT ?';
    params.push(parseInt(limit));

    const diagnostics = await dbAll(sql, params);

    // Retirer image_base64 pour réduire la taille de la réponse
    const diagnosticsWithoutImages = diagnostics.map(d => {
      const { image_base64, ...rest } = d;
      return {
        ...rest,
        resultat_ia: d.resultat_ia ? JSON.parse(d.resultat_ia) : null
      };
    });

    res.json(diagnosticsWithoutImages);
  } catch (error) {
    console.error('Erreur lors de la récupération des diagnostics:', error);
    res.status(500).json({ error: 'Erreur serveur lors de la récupération des diagnostics' });
  }
});

// Obtenir un diagnostic spécifique
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const diagnostic = await dbGet('SELECT * FROM diagnostics WHERE id = ?', [id]);

    if (!diagnostic) {
      return res.status(404).json({ error: 'Diagnostic non trouvé' });
    }

    const { image_base64, ...rest } = diagnostic;
    res.json({
      ...rest,
      resultat_ia: diagnostic.resultat_ia ? JSON.parse(diagnostic.resultat_ia) : null
    });
  } catch (error) {
    console.error('Erreur lors de la récupération du diagnostic:', error);
    res.status(500).json({ error: 'Erreur serveur lors de la récupération du diagnostic' });
  }
});

// Mettre à jour les statistiques quotidiennes
async function updateDailyStats(maladie_type, statut, region) {
  try {
    const today = new Date().toISOString().split('T')[0];
    
    // Vérifier si une entrée existe déjà pour aujourd'hui
    const existing = await dbGet(
      'SELECT * FROM daily_stats WHERE date = ? AND maladie_type = ? AND region = ?',
      [today, maladie_type, region || 'Togo']
    );

    if (existing) {
      // Mettre à jour
      const cas_positifs = statut === 'positif' ? existing.cas_positifs + 1 : existing.cas_positifs;
      const cas_negatifs = statut === 'negatif' ? existing.cas_negatifs + 1 : existing.cas_negatifs;
      const cas_totaux = existing.cas_totaux + 1;
      const taux_positivite = (cas_positifs / cas_totaux) * 100;

      await dbRun(
        `UPDATE daily_stats SET 
          cas_positifs = ?, 
          cas_negatifs = ?, 
          cas_totaux = ?, 
          taux_positivite = ?
        WHERE id = ?`,
        [cas_positifs, cas_negatifs, cas_totaux, taux_positivite, existing.id]
      );
    } else {
      // Créer une nouvelle entrée
      const cas_positifs = statut === 'positif' ? 1 : 0;
      const cas_negatifs = statut === 'negatif' ? 1 : 0;
      const cas_totaux = 1;
      const taux_positivite = statut === 'positif' ? 100 : 0;

      await dbRun(
        `INSERT INTO daily_stats (date, region, maladie_type, cas_positifs, cas_negatifs, cas_totaux, taux_positivite)
         VALUES (?, ?, ?, ?, ?, ?, ?)`,
        [today, region || 'Togo', maladie_type, cas_positifs, cas_negatifs, cas_totaux, taux_positivite]
      );
    }
  } catch (error) {
    console.error('Erreur lors de la mise à jour des statistiques:', error);
  }
}

// Vérifier les clusters épidémiques (détection simple) avec notifications
async function checkEpidemicClusters(region, prefecture, maladie_type, io = null) {
  try {
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
    const dateLimit = sevenDaysAgo.toISOString().split('T')[0];

    // Compter les cas positifs dans la région sur les 7 derniers jours
    const result = await dbGet(
      `SELECT COUNT(*) as count 
       FROM diagnostics 
       WHERE region = ? 
       AND maladie_type = ? 
       AND statut = 'positif' 
       AND DATE(created_at) >= ?`,
      [region || 'Togo', maladie_type, dateLimit]
    );

    const casCount = result?.count || 0;

    // Seuil d'alerte: 10 cas ou plus sur 7 jours = cluster potentiel
    if (casCount >= 10) {
      // Vérifier si un cluster existe déjà
      const existing = await dbGet(
        `SELECT * FROM epidemics 
         WHERE region = ? 
         AND maladie_type = ? 
         AND statut = 'actif'`,
        [region || 'Togo', maladie_type]
      );

      if (!existing) {
        // Créer un nouveau cluster épidémique
        const niveauAlerte = casCount >= 50 ? 'rouge' : casCount >= 30 ? 'orange' : 'jaune';
        
        const epidemicResult = await dbRun(
          `INSERT INTO epidemics (region, prefecture, maladie_type, nombre_cas, date_debut, niveau_alerte)
           VALUES (?, ?, ?, ?, ?, ?)`,
          [region || 'Togo', prefecture || null, maladie_type, casCount, new Date().toISOString().split('T')[0], niveauAlerte]
        );

        console.log(`⚠️ Cluster épidémique détecté: ${maladie_type} dans ${region} (${casCount} cas)`);
        
        // Notifier les superviseurs (si io disponible)
        if (io) {
          const notificationService = require('../services/notification_service');
          try {
            await notificationService.notifySupervisorsInRegion(
              region,
              'epidemic_alert',
              '⚠️ Cluster épidémique détecté',
              `Un cluster de ${maladie_type} a été détecté dans ${region} (${casCount} cas)`,
              'epidemic',
              epidemicResult.lastID,
              io
            );
          } catch (err) {
            console.error('Erreur notification cluster:', err);
          }
        }
      } else {
        // Mettre à jour le cluster existant
        await dbRun(
          `UPDATE epidemics SET nombre_cas = ?, niveau_alerte = ?
           WHERE id = ?`,
          [
            casCount,
            casCount >= 50 ? 'rouge' : casCount >= 30 ? 'orange' : 'jaune',
            existing.id
          ]
        );
      }
    }
  } catch (error) {
    console.error('Erreur lors de la vérification des clusters:', error);
  }
}

module.exports = router;


