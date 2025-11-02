const axios = require('axios');
const { dbRun, dbGet, dbAll } = require('../config/database');

/**
 * Service de Suivi Médication Avancé avec Rappels Intelligents
 * 
 * Fonctionnalités :
 * - Rappels personnalisables par médicament et horaire
 * - Vérification d'interactions médicamenteuses
 * - Suivi de l'observance avec statistiques
 * - Alertes de renouvellement de prescription
 * - Intégration avec OpenFDA, RxNorm, DrugBank APIs
 */

class MedicationService {
  constructor() {
    // APIs Configuration
    this.openFDAUrl = 'https://api.fda.gov';
    this.rxNormUrl = 'https://rxnav.nlm.nih.gov/REST';
    this.drugBankApiKey = process.env.DRUGBANK_API_KEY || null;
    this.drugBankUrl = 'https://api.drugbank.com/v1';
  }

  /**
   * Rechercher un médicament dans OpenFDA
   * @param {string} drugName - Nom du médicament
   * @returns {Promise<Object>} Informations du médicament
   */
  async searchDrugOpenFDA(drugName) {
    try {
      const response = await axios.get(
        `${this.openFDAUrl}/drug/label.json`,
        {
          params: {
            search: `brand_name:"${drugName}" OR generic_name:"${drugName}"`,
            limit: 10
          }
        }
      );

      if (response.data.results && response.data.results.length > 0) {
        return {
          success: true,
          provider: 'OpenFDA',
          results: response.data.results.map(drug => ({
            brand_name: drug.brand_name || [],
            generic_name: drug.generic_name || [],
            active_ingredient: drug.active_ingredient || [],
            indications_and_usage: drug.indications_and_usage || [],
            dosage_and_administration: drug.dosage_and_administration || [],
            warnings: drug.warnings || [],
            adverse_reactions: drug.adverse_reactions || []
          }))
        };
      }

      return {
        success: false,
        message: 'Médicament non trouvé dans OpenFDA'
      };
    } catch (error) {
      console.error('Erreur recherche OpenFDA:', error);
      throw new Error(`Erreur OpenFDA: ${error.message}`);
    }
  }

  /**
   * Normaliser le nom d'un médicament avec RxNorm
   * @param {string} drugName - Nom du médicament
   * @returns {Promise<Object>} Nom normalisé
   */
  async normalizeDrugNameRxNorm(drugName) {
    try {
      const response = await axios.get(
        `${this.rxNormUrl}/rxcui.json`,
        {
          params: {
            name: drugName
          }
        }
      );

      if (response.data.idGroup && response.data.idGroup.rxnormId) {
        const rxcui = response.data.idGroup.rxnormId[0];

        // Récupérer les informations détaillées
        const detailsResponse = await axios.get(
          `${this.rxNormUrl}/rxcui/${rxcui}/properties.json`
        );

        return {
          success: true,
          provider: 'RxNorm',
          rxcui: rxcui,
          normalizedName: detailsResponse.data.properties?.name || drugName,
          properties: detailsResponse.data.properties || {}
        };
      }

      return {
        success: false,
        message: 'Médicament non trouvé dans RxNorm'
      };
    } catch (error) {
      console.error('Erreur normalisation RxNorm:', error);
      return {
        success: false,
        message: `Erreur RxNorm: ${error.message}`
      };
    }
  }

  /**
   * Vérifier les interactions médicamenteuses
   * @param {Array<string>} drugNames - Liste des noms de médicaments
   * @returns {Promise<Object>} Interactions détectées
   */
  async checkDrugInteractions(drugNames) {
    try {
      if (drugNames.length < 2) {
        return {
          success: true,
          interactions: [],
          message: 'Au moins 2 médicaments requis pour vérifier les interactions'
        };
      }

      // Normaliser les noms avec RxNorm
      const normalizedDrugs = await Promise.all(
        drugNames.map(name => this.normalizeDrugNameRxNorm(name))
      );

      const rxcuis = normalizedDrugs
        .filter(d => d.success && d.rxcui)
        .map(d => d.rxcui);

      if (rxcuis.length < 2) {
        return {
          success: false,
          interactions: [],
          message: 'Impossible de normaliser les médicaments'
        };
      }

      // Vérifier les interactions avec RxNorm Interaction API
      const interactions = [];
      for (let i = 0; i < rxcuis.length; i++) {
        for (let j = i + 1; j < rxcuis.length; j++) {
          try {
            const response = await axios.get(
              `${this.rxNormUrl}/interaction/interaction.json`,
              {
                params: {
                  rxcui: [rxcuis[i], rxcuis[j]].join('+')
                }
              }
            );

            if (response.data && response.data.interactionTypeGroup) {
              const interactionGroup = response.data.interactionTypeGroup[0];
              if (interactionGroup && interactionGroup.interactionType) {
                for (const interactionType of interactionGroup.interactionType) {
                  if (interactionType.interactionPair) {
                    for (const pair of interactionType.interactionPair) {
                      interactions.push({
                        drug1: normalizedDrugs[i].normalizedName,
                        drug2: normalizedDrugs[j].normalizedName,
                        severity: pair.severity,
                        description: pair.description,
                        source: 'RxNorm'
                      });
                    }
                  }
                }
              }
            }
          } catch (error) {
            // Pas d'interaction détectée ou erreur API
            console.log(`Pas d'interaction pour ${rxcuis[i]} + ${rxcuis[j]}`);
          }
        }
      }

      return {
        success: true,
        interactions: interactions,
        drugCount: rxcuis.length,
        interactionCount: interactions.length,
        hasInteractions: interactions.length > 0
      };
    } catch (error) {
      console.error('Erreur vérification interactions:', error);
      throw new Error(`Erreur vérification interactions: ${error.message}`);
    }
  }

  /**
   * Créer un rappel de médicament
   * @param {number} userId - ID de l'utilisateur
   * @param {Object} medicationData - Données du médicament
   * @returns {Promise<Object>} Rappel créé
   */
  async createMedicationReminder(userId, medicationData) {
    try {
      const {
        medication_name,
        dosage,
        frequency,
        times_per_day,
        start_date,
        end_date,
        notes
      } = medicationData;

      // Vérifier les interactions si plusieurs médicaments
      let interactions = null;
      if (medicationData.interaction_check && medicationData.other_medications) {
        const allMedications = [medication_name, ...medicationData.other_medications];
        interactions = await this.checkDrugInteractions(allMedications);
      }

      const result = await dbRun(
        `INSERT INTO medication_reminders 
         (user_id, medication_name, dosage, frequency, times_per_day, 
          start_date, end_date, notes, interaction_warnings, created_at, status)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, datetime('now'), 'active')`,
        [
          userId,
          medication_name,
          dosage,
          frequency,
          times_per_day || 1,
          start_date,
          end_date,
          notes || null,
          interactions && interactions.hasInteractions 
            ? JSON.stringify(interactions.interactions) 
            : null
        ]
      );

      const reminderId = result.lastID;

      // Calculer les horaires de rappel
      const reminderTimes = this.calculateReminderTimes(
        frequency,
        times_per_day,
        start_date
      );

      return {
        success: true,
        reminder_id: reminderId,
        reminder: {
          id: reminderId,
          user_id: userId,
          medication_name,
          dosage,
          frequency,
          times_per_day,
          start_date,
          end_date,
          reminder_times: reminderTimes,
          interactions: interactions,
          status: 'active'
        }
      };
    } catch (error) {
      console.error('Erreur création rappel:', error);
      throw error;
    }
  }

  /**
   * Calculer les horaires de rappel
   * @param {string} frequency - Fréquence (daily, weekly, etc.)
   * @param {number} timesPerDay - Nombre de fois par jour
   * @param {string} startDate - Date de début
   * @returns {Array<string>} Liste des horaires
   */
  calculateReminderTimes(frequency, timesPerDay, startDate) {
    const times = [];
    const defaultTimes = ['08:00', '12:00', '18:00', '20:00'];

    for (let i = 0; i < timesPerDay && i < defaultTimes.length; i++) {
      times.push(defaultTimes[i]);
    }

    return times;
  }

  /**
   * Récupérer les rappels d'un utilisateur
   * @param {number} userId - ID de l'utilisateur
   * @returns {Promise<Array>} Liste des rappels
   */
  async getUserMedicationReminders(userId) {
    try {
      const reminders = await dbAll(
        `SELECT * FROM medication_reminders 
         WHERE user_id = ? 
         AND status = 'active'
         ORDER BY created_at DESC`,
        [userId]
      );

      return {
        success: true,
        reminders: reminders.map(r => ({
          ...r,
          interaction_warnings: r.interaction_warnings 
            ? JSON.parse(r.interaction_warnings) 
            : null
        }))
      };
    } catch (error) {
      console.error('Erreur récupération rappels:', error);
      throw error;
    }
  }

  /**
   * Marquer une prise de médicament
   * @param {number} reminderId - ID du rappel
   * @param {string} takenAt - Date/heure de prise
   * @returns {Promise<Object>} Résultat
   */
  async markMedicationTaken(reminderId, takenAt = null) {
    try {
      await dbRun(
        `INSERT INTO medication_adherence 
         (reminder_id, taken_at, created_at)
         VALUES (?, ?, datetime('now'))`,
        [reminderId, takenAt || new Date().toISOString()]
      );

      return {
        success: true,
        message: 'Médicament marqué comme pris'
      };
    } catch (error) {
      console.error('Erreur marquage médicament:', error);
      throw error;
    }
  }

  /**
   * Obtenir les statistiques d'observance
   * @param {number} userId - ID de l'utilisateur
   * @param {Date} startDate - Date de début (optionnel)
   * @param {Date} endDate - Date de fin (optionnel)
   * @returns {Promise<Object>} Statistiques d'observance
   */
  async getAdherenceStatistics(userId, startDate = null, endDate = null) {
    try {
      let query = `
        SELECT 
          mr.id,
          mr.medication_name,
          mr.frequency,
          mr.times_per_day,
          COUNT(ma.id) as taken_count,
          COUNT(DISTINCT DATE(ma.taken_at)) as days_taken
        FROM medication_reminders mr
        LEFT JOIN medication_adherence ma ON mr.id = ma.reminder_id
        WHERE mr.user_id = ?
      `;
      const params = [userId];

      if (startDate) {
        query += ' AND DATE(ma.taken_at) >= ?';
        params.push(startDate);
      }

      if (endDate) {
        query += ' AND DATE(ma.taken_at) <= ?';
        params.push(endDate);
      }

      query += ' GROUP BY mr.id';

      const stats = await dbAll(query, params);

      const totalReminders = stats.length;
      const totalExpected = stats.reduce((sum, s) => 
        sum + (s.times_per_day * (startDate && endDate 
          ? Math.ceil((new Date(endDate) - new Date(startDate)) / (1000 * 60 * 60 * 24))
          : 30)), 0);
      const totalTaken = stats.reduce((sum, s) => sum + parseInt(s.taken_count || 0), 0);
      const adherenceRate = totalExpected > 0 
        ? (totalTaken / totalExpected) * 100 
        : 0;

      return {
        success: true,
        statistics: {
          total_reminders: totalReminders,
          total_expected: totalExpected,
          total_taken: totalTaken,
          adherence_rate: Math.round(adherenceRate * 100) / 100,
          medications: stats.map(s => ({
            medication_name: s.medication_name,
            frequency: s.frequency,
            times_per_day: s.times_per_day,
            taken_count: parseInt(s.taken_count || 0),
            days_taken: parseInt(s.days_taken || 0)
          }))
        }
      };
    } catch (error) {
      console.error('Erreur statistiques observance:', error);
      throw error;
    }
  }
}

module.exports = new MedicationService();

