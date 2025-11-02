const { dbGet, dbAll } = require('../config/database');

/**
 * Service de Contact Tracing / Investigation d'Épidémie
 * 
 * Fonctionnalités :
 * - Traçage automatique des contacts d'un patient infecté
 * - Calcul du R0 (taux de reproduction de base)
 * - Graphique de transmission (qui a infecté qui)
 * - Alertes automatiques aux contacts à risque
 */

class ContactTracingService {
  constructor() {
    this.contactRadiusMeters = 50; // Rayon de contact en mètres
    this.contactTimeWindow = 14; // Fenêtre temporelle en jours
    this.R0CalculationPeriod = 30; // Période pour calculer R0 en jours
  }

  /**
   * Trouver tous les contacts d'un patient infecté
   * @param {number} diagnosticId - ID du diagnostic infecté
   * @returns {Promise<Array>} Liste des contacts
   */
  async findContacts(diagnosticId) {
    try {
      // Récupérer le diagnostic infecté
      const diagnostic = await dbGet(
        `SELECT id, user_id, maladie_type, statut, latitude, longitude, 
         created_at, region
         FROM diagnostics 
         WHERE id = ? AND statut = 'positif'`,
        [diagnosticId]
      );

      if (!diagnostic) {
        throw new Error('Diagnostic non trouvé ou non infecté');
      }

      // Date limite pour les contacts (X jours avant)
      const dateLimit = new Date(diagnostic.created_at);
      dateLimit.setDate(dateLimit.getDate() - this.contactTimeWindow);

      // Trouver tous les diagnostics dans le rayon et la fenêtre temporelle
      const contacts = await dbAll(
        `SELECT d.*, 
         (6371000 * acos(
           cos(radians(?)) * cos(radians(d.latitude)) *
           cos(radians(d.longitude) - radians(?)) +
           sin(radians(?)) * sin(radians(d.latitude))
         )) AS distance_meters
         FROM diagnostics d
         WHERE d.id != ?
         AND d.statut IN ('positif', 'incertain')
         AND d.created_at BETWEEN ? AND ?
         AND d.latitude IS NOT NULL 
         AND d.longitude IS NOT NULL
         HAVING distance_meters <= ?
         ORDER BY d.created_at DESC`,
        [
          diagnostic.latitude,
          diagnostic.longitude,
          diagnostic.latitude,
          diagnosticId,
          dateLimit.toISOString(),
          diagnostic.created_at,
          this.contactRadiusMeters
        ]
      );

      // Enrichir avec les informations des utilisateurs
      const enrichedContacts = await Promise.all(
        contacts.map(async (contact) => {
          const user = await dbGet(
            'SELECT id, username, email, phone, role FROM users WHERE id = ?',
            [contact.user_id]
          );
          return {
            ...contact,
            user,
            contact_date: contact.created_at,
            distance_meters: Math.round(contact.distance_meters)
          };
        })
      );

      return enrichedContacts;
    } catch (error) {
      console.error('Erreur contact tracing:', error);
      throw error;
    }
  }

  /**
   * Construire le graphique de transmission
   * @param {number} patientId - ID du patient initial
   * @param {number} maxDepth - Profondeur maximale de recherche
   * @returns {Promise<Object>} Graphique de transmission
   */
  async buildTransmissionGraph(patientId, maxDepth = 5) {
    try {
      const graph = {
        nodes: [],
        edges: [],
        rootPatientId: patientId
      };

      // Fonction récursive pour construire le graphe
      const buildGraph = async (currentPatientId, depth, visited = new Set()) => {
        if (depth > maxDepth || visited.has(currentPatientId)) {
          return;
        }

        visited.add(currentPatientId);

        // Trouver tous les diagnostics positifs de ce patient
        const diagnostics = await dbAll(
          `SELECT id, maladie_type, statut, created_at, latitude, longitude, region
           FROM diagnostics
           WHERE user_id = ? AND statut = 'positif'
           ORDER BY created_at ASC`,
          [currentPatientId]
        );

        for (const diagnostic of diagnostics) {
          // Ajouter le nœud
          if (!graph.nodes.find(n => n.id === diagnostic.id)) {
            graph.nodes.push({
              id: diagnostic.id,
              patientId: currentPatientId,
              maladie_type: diagnostic.maladie_type,
              date: diagnostic.created_at,
              region: diagnostic.region,
              latitude: diagnostic.longitude,
              longitude: diagnostic.latitude
            });
          }

          // Trouver les contacts de ce diagnostic
          const contacts = await this.findContacts(diagnostic.id);

          for (const contact of contacts) {
            const contactPatientId = contact.user_id;

            // Ajouter le nœud contact
            if (!graph.nodes.find(n => n.patientId === contactPatientId && 
              n.date === contact.created_at)) {
              graph.nodes.push({
                id: contact.id,
                patientId: contactPatientId,
                maladie_type: contact.maladie_type,
                date: contact.created_at,
                region: contact.region,
                latitude: contact.longitude,
                longitude: contact.latitude,
                isContact: true
              });
            }

            // Ajouter l'arête (lien de transmission)
            if (!graph.edges.find(e => 
              e.source === diagnostic.id && e.target === contact.id)) {
              graph.edges.push({
                source: diagnostic.id,
                target: contact.id,
                distance: contact.distance_meters,
                date: contact.created_at
              });
            }

            // Construire récursivement pour les contacts
            await buildGraph(contactPatientId, depth + 1, visited);
          }
        }
      };

      await buildGraph(patientId, 0);

      return graph;
    } catch (error) {
      console.error('Erreur construction graph transmission:', error);
      throw error;
    }
  }

  /**
   * Calculer le R0 (taux de reproduction de base)
   * @param {string} region - Région (optionnel)
   * @param {Date} startDate - Date de début (optionnel)
   * @param {Date} endDate - Date de fin (optionnel)
   * @returns {Promise<Object>} Statistiques R0
   */
  async calculateR0(region = null, startDate = null, endDate = null) {
    try {
      let query = `
        SELECT d.id, d.user_id, d.created_at, d.maladie_type, d.region
        FROM diagnostics d
        WHERE d.statut = 'positif'
        AND d.created_at >= DATE('now', '-' || ? || ' days')
      `;
      const params = [this.R0CalculationPeriod];

      if (region) {
        query += ' AND d.region = ?';
        params.push(region);
      }

      if (startDate) {
        query += ' AND d.created_at >= ?';
        params.push(startDate);
      }

      if (endDate) {
        query += ' AND d.created_at <= ?';
        params.push(endDate);
      }

      const diagnostics = await dbAll(query, params);

      let totalContacts = 0;
      let infectedContacts = 0;

      for (const diagnostic of diagnostics) {
        const contacts = await this.findContacts(diagnostic.id);
        totalContacts += contacts.length;

        // Compter les contacts qui sont devenus infectés
        for (const contact of contacts) {
          const contactLaterDiagnostics = await dbAll(
            `SELECT COUNT(*) as count
             FROM diagnostics
             WHERE user_id = ?
             AND created_at > ?
             AND statut = 'positif'`,
            [contact.user_id, contact.created_at]
          );

          if (contactLaterDiagnostics[0]?.count > 0) {
            infectedContacts++;
          }
        }
      }

      const totalInfected = diagnostics.length;
      const avgContactsPerInfected = totalInfected > 0 ? totalContacts / totalInfected : 0;
      const transmissionRate = totalContacts > 0 ? infectedContacts / totalContacts : 0;
      const R0 = avgContactsPerInfected * transmissionRate;

      return {
        R0: Math.round(R0 * 100) / 100,
        totalInfected,
        totalContacts,
        infectedContacts,
        avgContactsPerInfected: Math.round(avgContactsPerInfected * 100) / 100,
        transmissionRate: Math.round(transmissionRate * 100) / 100,
        period: this.R0CalculationPeriod,
        region: region || 'toutes'
      };
    } catch (error) {
      console.error('Erreur calcul R0:', error);
      throw error;
    }
  }

  /**
   * Générer un rapport d'investigation épidémique
   * @param {number} diagnosticId - ID du diagnostic initial
   * @returns {Promise<Object>} Rapport complet
   */
  async generateInvestigationReport(diagnosticId) {
    try {
      const diagnostic = await dbGet(
        `SELECT d.*, u.username, u.email, u.phone, u.role
         FROM diagnostics d
         JOIN users u ON d.user_id = u.id
         WHERE d.id = ?`,
        [diagnosticId]
      );

      if (!diagnostic) {
        throw new Error('Diagnostic non trouvé');
      }

      const contacts = await this.findContacts(diagnosticId);
      const transmissionGraph = await this.buildTransmissionGraph(diagnostic.user_id);
      const R0Stats = await this.calculateR0(diagnostic.region);

      return {
        diagnostic: {
          id: diagnostic.id,
          maladie_type: diagnostic.maladie_type,
          statut: diagnostic.statut,
          date: diagnostic.created_at,
          region: diagnostic.region,
          location: {
            latitude: diagnostic.latitude,
            longitude: diagnostic.longitude,
            adresse: diagnostic.adresse
          },
          patient: {
            id: diagnostic.user_id,
            username: diagnostic.username,
            email: diagnostic.email,
            phone: diagnostic.phone
          }
        },
        contacts: {
          total: contacts.length,
          list: contacts.map(c => ({
            id: c.id,
            patient_id: c.user_id,
            username: c.user?.username,
            email: c.user?.email,
            phone: c.user?.phone,
            maladie_type: c.maladie_type,
            date: c.created_at,
            distance_meters: c.distance_meters,
            region: c.region
          }))
        },
        transmissionGraph: {
          nodes: transmissionGraph.nodes.length,
          edges: transmissionGraph.edges.length,
          graph: transmissionGraph
        },
        epidemiology: {
          R0: R0Stats.R0,
          region: R0Stats.region,
          stats: R0Stats
        },
        recommendations: this.generateRecommendations(contacts.length, R0Stats.R0),
        generated_at: new Date().toISOString()
      };
    } catch (error) {
      console.error('Erreur génération rapport:', error);
      throw error;
    }
  }

  /**
   * Générer des recommandations basées sur les statistiques
   * @param {number} contactCount - Nombre de contacts
   * @param {number} R0 - Taux de reproduction
   * @returns {Array<string>} Liste de recommandations
   */
  generateRecommendations(contactCount, R0) {
    const recommendations = [];

    if (contactCount > 10) {
      recommendations.push('⚠️ Nombre élevé de contacts détectés. Mise en quarantaine recommandée.');
    }

    if (R0 > 1) {
      recommendations.push('🚨 R0 > 1 : L\'épidémie est en expansion. Actions urgentes nécessaires.');
    } else if (R0 < 1) {
      recommendations.push('✅ R0 < 1 : L\'épidémie est sous contrôle.');
    }

    if (contactCount > 5) {
      recommendations.push('📢 Campagne de sensibilisation recommandée dans la zone.');
    }

    if (contactCount === 0) {
      recommendations.push('✅ Aucun contact détecté. Risque de transmission faible.');
    }

    return recommendations;
  }
}

module.exports = new ContactTracingService();

