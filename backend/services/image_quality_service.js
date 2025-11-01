const sharp = require('sharp');

/**
 * Analyse la qualité d'une image
 * @param {Buffer} imageBuffer - Buffer de l'image
 * @returns {Promise<Object>} - Métriques de qualité
 */
async function analyzeImageQuality(imageBuffer) {
  try {
    const metadata = await sharp(imageBuffer).metadata();
    const stats = await sharp(imageBuffer).stats();
    
    // Calcul de la netteté (via variance de Laplacien approximé)
    const sharpness = await calculateSharpness(imageBuffer);
    
    // Calcul du contraste
    const contrast = calculateContrast(stats);
    
    // Calcul du bruit
    const noise = calculateNoise(stats);
    
    // Calcul de l'exposition (luminosité moyenne)
    const exposure = calculateExposure(stats);
    
    // Score global (0-100)
    const qualityScore = calculateQualityScore({
      sharpness,
      contrast,
      noise,
      exposure,
      width: metadata.width,
      height: metadata.height,
    });
    
    return {
      quality_score: qualityScore,
      sharpness,
      contrast,
      noise,
      exposure,
      resolution: {
        width: metadata.width,
        height: metadata.height,
        megapixels: (metadata.width * metadata.height) / 1000000,
      },
      recommendations: generateRecommendations({
        qualityScore,
        sharpness,
        contrast,
        exposure,
      }),
    };
  } catch (error) {
    console.error('Erreur analyse qualité image:', error);
    return null;
  }
}

/**
 * Calcul approximatif de la netteté (variance de Laplacien)
 */
async function calculateSharpness(imageBuffer) {
  try {
    // Convertir en niveaux de gris et appliquer un filtre Laplacien
    const grayscale = await sharp(imageBuffer)
      .greyscale()
      .normalize()
      .toBuffer();
    
    const { data, info } = await sharp(grayscale)
      .raw()
      .toBuffer({ resolveWithObject: true });
    
    // Calcul de la variance (approximation simple)
    let sum = 0;
    let sumSquares = 0;
    const pixelCount = data.length;
    
    for (let i = 0; i < pixelCount; i++) {
      const value = data[i];
      sum += value;
      sumSquares += value * value;
    }
    
    const mean = sum / pixelCount;
    const variance = (sumSquares / pixelCount) - (mean * mean);
    
    // Normaliser entre 0-100 (empirique)
    return Math.min(100, Math.max(0, variance / 100));
  } catch (error) {
    return 50; // Valeur par défaut
  }
}

/**
 * Calcul du contraste (écart-type des intensités)
 */
function calculateContrast(stats) {
  const channels = stats.channels;
  if (!channels || channels.length === 0) return 50;
  
  // Utiliser le canal principal (rouge ou gris)
  const channel = channels[0];
  const stddev = channel.stdev || 0;
  
  // Normaliser entre 0-100
  return Math.min(100, Math.max(0, (stddev / 255) * 100));
}

/**
 * Calcul approximatif du bruit
 */
function calculateNoise(stats) {
  const channels = stats.channels;
  if (!channels || channels.length === 0) return 0;
  
  // Estimation basée sur les écarts
  const channel = channels[0];
  const noise = (channel.stdev || 0) / (channel.mean || 1);
  
  // Normaliser entre 0-100 (plus bas = moins de bruit)
  return Math.min(100, Math.max(0, 100 - (noise * 1000)));
}

/**
 * Calcul de l'exposition (luminosité moyenne)
 */
function calculateExposure(stats) {
  const channels = stats.channels;
  if (!channels || channels.length === 0) return 50;
  
  // Utiliser le canal principal
  const channel = channels[0];
  const mean = channel.mean || 0;
  
  // Normaliser entre 0-100 (128 = idéal)
  const ideal = 128;
  const deviation = Math.abs(mean - ideal);
  return Math.max(0, 100 - (deviation / 128) * 100);
}

/**
 * Calcul du score de qualité global
 */
function calculateQualityScore(metrics) {
  const weights = {
    sharpness: 0.3,
    contrast: 0.25,
    noise: 0.2,
    exposure: 0.15,
    resolution: 0.1,
  };
  
  // Score de résolution (min 0.5MP = 0, 8MP+ = 100)
  const resolutionScore = Math.min(100, (metrics.resolution.megapixels / 8) * 100);
  
  const score = (
    metrics.sharpness * weights.sharpness +
    metrics.contrast * weights.contrast +
    metrics.noise * weights.noise +
    metrics.exposure * weights.exposure +
    resolutionScore * weights.resolution
  );
  
  return Math.round(Math.max(0, Math.min(100, score)));
}

/**
 * Générer des recommandations basées sur les métriques
 */
function generateRecommendations(metrics) {
  const recommendations = [];
  
  if (metrics.sharpness < 40) {
    recommendations.push({
      type: 'warning',
      message: 'Image floue. Recommandation: stabiliser l\'appareil ou augmenter la netteté.',
    });
  }
  
  if (metrics.contrast < 30) {
    recommendations.push({
      type: 'warning',
      message: 'Contraste faible. Recommandation: améliorer l\'éclairage ou ajuster le contraste.',
    });
  }
  
  if (metrics.exposure < 40) {
    recommendations.push({
      type: 'warning',
      message: 'Exposition incorrecte. Recommandation: ajuster la luminosité ou utiliser le flash.',
    });
  }
  
  if (metrics.qualityScore < 50) {
    recommendations.push({
      type: 'error',
      message: 'Qualité d\'image insuffisante pour un diagnostic fiable. Veuillez reprendre la photo.',
    });
  }
  
  return recommendations;
}

module.exports = {
  analyzeImageQuality,
};
