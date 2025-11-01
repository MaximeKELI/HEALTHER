const { dbAll, dbGet } = require('../config/database');

/**
 * Recherche avancée de diagnostics
 * @param {Object} filters - Filtres de recherche
 * @returns {Promise<Array>} - Résultats de recherche
 */
async function searchDiagnostics(filters) {
  let sql = 'SELECT * FROM diagnostics WHERE 1=1';
  const params = [];
  
  // Filtres de base
  if (filters.user_id) {
    sql += ' AND user_id = ?';
    params.push(filters.user_id);
  }
  
  if (filters.maladie_type) {
    sql += ' AND maladie_type = ?';
    params.push(filters.maladie_type);
  }
  
  if (filters.region) {
    sql += ' AND region = ?';
    params.push(filters.region);
  }
  
  if (filters.statut) {
    sql += ' AND statut = ?';
    params.push(filters.statut);
  }
  
  // Recherche par dates
  if (filters.date_debut) {
    sql += ' AND DATE(created_at) >= ?';
    params.push(filters.date_debut);
  }
  
  if (filters.date_fin) {
    sql += ' AND DATE(created_at) <= ?';
    params.push(filters.date_fin);
  }
  
  // Recherche par plage de confiance
  if (filters.confiance_min !== undefined) {
    sql += ' AND confiance >= ?';
    params.push(filters.confiance_min);
  }
  
  if (filters.confiance_max !== undefined) {
    sql += ' AND confiance <= ?';
    params.push(filters.confiance_max);
  }
  
  // Recherche par qualité d'image
  if (filters.quality_min !== undefined) {
    sql += ' AND image_quality_metrics IS NOT NULL';
    sql += ' AND JSON_EXTRACT(image_quality_metrics, "$.quality_score") >= ?';
    params.push(filters.quality_min);
  }
  
  // Tri
  const sortBy = filters.sort_by || 'created_at';
  const sortOrder = filters.sort_order || 'DESC';
  sql += ` ORDER BY ${sortBy} ${sortOrder}`;
  
  // Limite et pagination
  const limit = filters.limit || 50;
  const offset = filters.offset || 0;
  sql += ' LIMIT ? OFFSET ?';
  params.push(limit, offset);
  
  const results = await dbAll(sql, params);
  
  return results.map(r => ({
    ...r,
    resultat_ia: r.resultat_ia ? JSON.parse(r.resultat_ia) : null,
    image_quality_metrics: r.image_quality_metrics ? JSON.parse(r.image_quality_metrics) : null,
  }));
}

/**
 * Recherche de patients par identifiant
 * @param {string} query - Terme de recherche
 * @returns {Promise<Array>} - Résultats de recherche
 */
async function searchPatients(query) {
  if (!query || query.length < 2) {
    return [];
  }
  
  // Rechercher dans patient_history par identifiant
  const results = await dbAll(
    `SELECT DISTINCT patient_identifier,
     COUNT(*) as diagnostic_count,
     MAX(created_at) as last_diagnostic
     FROM patient_history
     WHERE patient_identifier LIKE ?
     GROUP BY patient_identifier
     ORDER BY last_diagnostic DESC
     LIMIT 20`,
    [`%${query}%`]
  );
  
  return results;
}

/**
 * Sauvegarder un filtre de recherche
 * @param {number} userId - ID utilisateur
 * @param {string} name - Nom du filtre
 * @param {Object} filters - Filtres à sauvegarder
 */
async function saveSearchFilter(userId, name, filters) {
  const { dbRun } = require('../config/database');
  
  await dbRun(
    `INSERT INTO saved_filters (user_id, name, filters, created_at)
     VALUES (?, ?, ?, CURRENT_TIMESTAMP)
     ON CONFLICT(user_id, name) DO UPDATE SET
       filters = ?,
       updated_at = CURRENT_TIMESTAMP`,
    [userId, name, JSON.stringify(filters), JSON.stringify(filters)]
  );
}

/**
 * Obtenir les filtres sauvegardés d'un utilisateur
 * @param {number} userId - ID utilisateur
 * @returns {Promise<Array>} - Filtres sauvegardés
 */
async function getSavedFilters(userId) {
  const results = await dbAll(
    'SELECT * FROM saved_filters WHERE user_id = ? ORDER BY updated_at DESC',
    [userId]
  );
  
  return results.map(r => ({
    ...r,
    filters: JSON.parse(r.filters),
  }));
}

module.exports = {
  searchDiagnostics,
  searchPatients,
  saveSearchFilter,
  getSavedFilters,
};
