const { dbRun, dbGet, dbAll } = require('../config/database');

/**
 * Ajouter un événement à l'historique patient
 * @param {string} patientIdentifier - Identifiant patient (téléphone, nom, etc.)
 * @param {number} diagnosticId - ID du diagnostic
 * @param {string} eventType - Type d'événement (diagnostic, traitement, suivi, etc.)
 * @param {Object} details - Détails de l'événement
 */
async function addPatientEvent(patientIdentifier, diagnosticId, eventType, details) {
  await dbRun(
    `INSERT INTO patient_history (patient_identifier, diagnostic_id, event_type, details)
     VALUES (?, ?, ?, ?)`,
    [patientIdentifier, diagnosticId, eventType, JSON.stringify(details)]
  );
}

/**
 * Obtenir l'historique complet d'un patient
 * @param {string} patientIdentifier - Identifiant patient
 * @returns {Promise<Array>} - Historique des événements
 */
async function getPatientHistory(patientIdentifier) {
  const history = await dbAll(
    `SELECT ph.*, d.maladie_type, d.statut, d.created_at as diagnostic_date
     FROM patient_history ph
     LEFT JOIN diagnostics d ON ph.diagnostic_id = d.id
     WHERE ph.patient_identifier = ?
     ORDER BY ph.created_at DESC`,
    [patientIdentifier]
  );
  
  return history.map(item => ({
    ...item,
    details: item.details ? JSON.parse(item.details) : null,
  }));
}

/**
 * Obtenir le profil patient consolidé
 * @param {string} patientIdentifier - Identifiant patient
 * @returns {Promise<Object>} - Profil patient
 */
async function getPatientProfile(patientIdentifier) {
  const history = await getPatientHistory(patientIdentifier);
  
  // Statistiques consolidées
  const diagnostics = history.filter(h => h.event_type === 'diagnostic');
  const totalDiagnostics = diagnostics.length;
  const positifDiagnostics = diagnostics.filter(d => d.statut === 'positif').length;
  const dernierDiagnostic = diagnostics[0];
  
  // Derniers traitements
  const traitements = history.filter(h => h.event_type === 'traitement');
  
  // Derniers suivis
  const suivis = history.filter(h => h.event_type === 'suivi');
  
  return {
    identifier: patientIdentifier,
    total_diagnostics: totalDiagnostics,
    positifs: positifDiagnostics,
    negatifs: totalDiagnostics - positifDiagnostics,
    dernier_diagnostic: dernierDiagnostic,
    derniers_traitements: traitements.slice(0, 5),
    derniers_suivis: suivis.slice(0, 5),
    historique_complet: history,
  };
}

module.exports = {
  addPatientEvent,
  getPatientHistory,
  getPatientProfile,
};
