const express = require('express');
const router = express.Router();
const mlService = require('../services/ml_service');

/**
 * Route pour analyser une image médicale
 * POST /api/ml/analyze
 * 
 * Body:
 * {
 *   "image_base64": "base64_encoded_image",
 *   "maladie_type": "paludisme" | "typhoide" | "mixte"
 * }
 */
router.post('/analyze', async (req, res) => {
  try {
    const { image_base64, maladie_type } = req.body;

    // Validation
    if (!image_base64) {
      return res.status(400).json({ error: 'image_base64 est requis' });
    }

    if (!maladie_type) {
      return res.status(400).json({ error: 'maladie_type est requis' });
    }

    const validTypes = ['paludisme', 'typhoide', 'mixte'];
    if (!validTypes.includes(maladie_type)) {
      return res.status(400).json({ 
        error: 'maladie_type doit être: paludisme, typhoide ou mixte' 
      });
    }

    // Analyser l'image avec le service ML
    const result = await mlService.analyzeImage(image_base64, maladie_type);

    res.json({
      success: true,
      result: result,
    });
  } catch (error) {
    console.error('Erreur lors de l\'analyse ML:', error);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de l\'analyse de l\'image',
      message: error.message,
    });
  }
});

/**
 * Route pour vérifier l'état du service ML
 * GET /api/ml/health
 */
router.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    model_loaded: mlService.modelLoaded,
    message: 'Service ML opérationnel',
  });
});

module.exports = router;

