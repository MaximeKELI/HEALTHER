const { dbAll, dbGet } = require('../config/database');

/**
 * Détecter les anomalies dans les diagnostics
 * @returns {Promise<Array>} - Liste des anomalies détectées
 */
async function detectAnomalies() {
  const anomalies = [];
  
  // 1. Sur-signalement: Région avec beaucoup plus de cas que la moyenne
  const statsByRegion = await dbAll(
    `SELECT region, COUNT(*) as total, 
     SUM(CASE WHEN statut = 'positif' THEN 1 ELSE 0 END) as positifs
     FROM diagnostics
     WHERE DATE(created_at) >= DATE('now', '-30 days')
     GROUP BY region`
  );
  
  if (statsByRegion.length > 0) {
    const moyenneCas = statsByRegion.reduce((sum, r) => sum + r.total, 0) / statsByRegion.length;
    const seuil = moyenneCas * 2; // 2x la moyenne
    
    for (const region of statsByRegion) {
      if (region.total > seuil) {
        anomalies.push({
          type: 'sur_signalement',
          severity: 'high',
          region: region.region,
          description: `Sur-signalement détecté: ${region.total} cas dans ${region.region} (moyenne: ${moyenneCas.toFixed(1)})`,
          cas_count: region.total,
          moyenne: moyenneCas,
        });
      }
    }
  }
  
  // 2. Doublons potentiels (même coordonnées, même jour)
  const doublons = await dbAll(
    `SELECT latitude, longitude, DATE(created_at) as date, COUNT(*) as count
     FROM diagnostics
     WHERE latitude IS NOT NULL AND longitude IS NOT NULL
     AND DATE(created_at) >= DATE('now', '-7 days')
     GROUP BY latitude, longitude, DATE(created_at)
     HAVING count > 3`
  );
  
  for (const doublon of doublons) {
    anomalies.push({
      type: 'doublon_potentiel',
      severity: 'medium',
      description: `${doublon.count} diagnostics au même endroit le ${doublon.date}`,
      latitude: doublon.latitude,
      longitude: doublon.longitude,
      date: doublon.date,
      count: doublon.count,
    });
  }
  
  // 3. Valeurs extrêmes de confiance
  const extremesConfiance = await dbAll(
    `SELECT id, confiance, maladie_type, statut, user_id
     FROM diagnostics
     WHERE confiance IS NOT NULL
     AND (confiance > 95 OR confiance < 20)
     AND DATE(created_at) >= DATE('now', '-7 days')
     ORDER BY ABS(confiance - 50) DESC
     LIMIT 10`
  );
  
  for (const extreme of extremesConfiance) {
    anomalies.push({
      type: 'confiance_extreme',
      severity: extreme.confiance > 95 ? 'low' : 'high',
      description: `Confiance ${extreme.confiance}% pour diagnostic ${extreme.id}`,
      diagnostic_id: extreme.id,
      confiance: extreme.confiance,
      maladie_type: extreme.maladie_type,
      statut: extreme.statut,
    });
  }
  
  // 4. Qualité d'image insuffisante
  const mauvaiseQualite = await dbAll(
    `SELECT id, image_quality_metrics, maladie_type, statut
     FROM diagnostics
     WHERE image_quality_metrics IS NOT NULL
     AND JSON_EXTRACT(image_quality_metrics, "$.quality_score") < 50
     AND DATE(created_at) >= DATE('now', '-7 days')
     ORDER BY JSON_EXTRACT(image_quality_metrics, "$.quality_score") ASC
     LIMIT 20`
  );
  
  for (const qualite of mauvaiseQualite) {
    const metrics = JSON.parse(qualite.image_quality_metrics);
    anomalies.push({
      type: 'qualite_insuffisante',
      severity: 'medium',
      description: `Qualité d'image ${metrics.quality_score}/100 pour diagnostic ${qualite.id}`,
      diagnostic_id: qualite.id,
      quality_score: metrics.quality_score,
      maladie_type: qualite.maladie_type,
      recommendations: metrics.recommendations || [],
    });
  }
  
  return anomalies;
}

/**
 * Détecter les patterns suspects
 */
async function detectSuspiciousPatterns() {
  const patterns = [];
  
  // Pattern: Même utilisateur, beaucoup de cas positifs rapidement
  const utilisateursActifs = await dbAll(
    `SELECT user_id, COUNT(*) as total_positifs, MIN(created_at) as premier, MAX(created_at) as dernier
     FROM diagnostics
     WHERE statut = 'positif'
     AND DATE(created_at) >= DATE('now', '-7 days')
     GROUP BY user_id
     HAVING total_positifs > 20`
  );
  
  for (const user of utilisateursActifs) {
    const premier = new Date(user.premier);
    const dernier = new Date(user.dernier);
    const jours = (dernier - premier) / (1000 * 60 * 60 * 24);
    const taux = user.total_positifs / jours;
    
    if (taux > 10) { // Plus de 10 cas positifs/jour
      patterns.push({
        type: 'pattern_suspect',
        severity: 'medium',
        description: `Utilisateur ${user.user_id}: ${user.total_positifs} cas positifs en ${jours.toFixed(1)} jours (${taux.toFixed(1)}/jour)`,
        user_id: user.user_id,
        total_positifs: user.total_positifs,
        taux_par_jour: taux,
      });
    }
  }
  
  return patterns;
}

module.exports = {
  detectAnomalies,
  detectSuspiciousPatterns,
};
