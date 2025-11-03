const { dbGet } = require('../config/database');

/**
 * Service pour les alertes proactives basées sur seuils
 */
class AlertService {
  /**
   * Vérifier les seuils et générer des alertes
   */
  async checkThresholds({ region, maladieType, days = 7 }) {
    try {
      // Récupérer les statistiques récentes
      const stats = await this._getRecentStats({ region, maladieType, days });

      // Vérifier les seuils configurés
      const thresholds = await this._getThresholds({ region, maladieType });
      
      const alerts = [];

      // Vérifier chaque seuil
      for (const threshold of thresholds) {
        const value = stats[threshold.metric] || 0;
        
        if (value >= threshold.warningLevel && value < threshold.criticalLevel) {
          alerts.push({
            type: 'warning',
            metric: threshold.metric,
            currentValue: value,
            threshold: threshold.warningLevel,
            message: `Seuil d'avertissement atteint pour ${threshold.metric}`,
            region: region || 'Toutes',
            date: new Date().toISOString(),
          });
        } else if (value >= threshold.criticalLevel) {
          alerts.push({
            type: 'critical',
            metric: threshold.metric,
            currentValue: value,
            threshold: threshold.criticalLevel,
            message: `Seuil critique atteint pour ${threshold.metric}!`,
            region: region || 'Toutes',
            date: new Date().toISOString(),
          });
        }
      }

      // Vérifier les tendances
      const trends = await this._checkTrends({ region, maladieType, days });
      alerts.push(...trends);

      return {
        alerts,
        hasAlerts: alerts.length > 0,
        stats,
        checkedAt: new Date().toISOString(),
      };
    } catch (error) {
      console.error('Erreur vérification seuils:', error);
      throw new Error(`Erreur vérification: ${error.message}`);
    }
  }

  /**
   * Obtenir les statistiques récentes
   * @private
   */
  async _getRecentStats({ region, maladieType, days }) {
    try {
      let query = `
        SELECT 
          COUNT(*) as total,
          SUM(CASE WHEN statut = 'positif' THEN 1 ELSE 0 END) as positifs,
          SUM(CASE WHEN maladie_type = 'paludisme' THEN 1 ELSE 0 END) as paludisme,
          SUM(CASE WHEN maladie_type = 'typhoide' THEN 1 ELSE 0 END) as typhoide
        FROM diagnostics
        WHERE created_at >= datetime('now', '-' || ? || ' days')
      `;
      
      const params = [days];
      
      if (region) {
        query += ' AND region = ?';
        params.push(region);
      }
      
      if (maladieType) {
        query += ' AND maladie_type = ?';
        params.push(maladieType);
      }
      
      const row = await dbGet(query, params);
      return row || {};
    } catch (error) {
      console.error('Erreur récupération stats:', error);
      return {};
    }
  }

  /**
   * Obtenir les seuils configurés
   * @private
   */
  async _getThresholds({ region, maladieType }) {
    // Seuils par défaut
    const defaultThresholds = [
      {
        metric: 'total',
        warningLevel: 50,
        criticalLevel: 100,
        region: null,
        maladieType: null,
      },
      {
        metric: 'positifs',
        warningLevel: 20,
        criticalLevel: 50,
        region: null,
        maladieType: null,
      },
      {
        metric: 'paludisme',
        warningLevel: 30,
        criticalLevel: 60,
        region: null,
        maladieType: 'paludisme',
      },
      {
        metric: 'typhoide',
        warningLevel: 15,
        criticalLevel: 30,
        region: null,
        maladieType: 'typhoide',
      },
    ];

    // Filtrer selon région/maladie si spécifié
    return defaultThresholds.filter((t) => {
      if (region && t.region && t.region !== region) return false;
      if (maladieType && t.maladieType && t.maladieType !== maladieType) return false;
      return true;
    });
  }

  /**
   * Vérifier les tendances
   * @private
   */
  async _checkTrends({ region, maladieType, days }) {
    try {
      // Comparer les 7 derniers jours avec les 7 jours précédents
      const recent = await this._getRecentStats({ region, maladieType, days: 7 });
      const previous = await this._getRecentStats({ region, maladieType, days: 14 });

      const alerts = [];
      
      // Calculer les augmentations
      if (previous.total > 0) {
        const growthRate = ((recent.total - previous.total) / previous.total) * 100;
        
        if (growthRate > 50) {
          alerts.push({
            type: 'warning',
            metric: 'growth_rate',
            currentValue: growthRate,
            message: `Augmentation de ${growthRate.toFixed(1)}% des diagnostics`,
            region: region || 'Toutes',
            date: new Date().toISOString(),
          });
        }
      }

      return alerts;
    } catch (error) {
      console.error('Erreur vérification tendances:', error);
      return [];
    }
  }

  /**
   * Configurer un seuil personnalisé
   */
  async setThreshold({
    metric,
    warningLevel,
    criticalLevel,
    region = null,
    maladieType = null,
  }) {
    try {
      // TODO: Stocker dans la base de données (table thresholds)
      // Pour l'instant, on retourne juste un succès
      return {
        success: true,
        threshold: {
          metric,
          warningLevel,
          criticalLevel,
          region,
          maladieType,
        },
      };
    } catch (error) {
      console.error('Erreur configuration seuil:', error);
      throw new Error(`Erreur configuration: ${error.message}`);
    }
  }

  /**
   * Obtenir l'historique des alertes
   */
  async getAlertHistory({ limit = 50, offset = 0 }) {
    try {
      // TODO: Stocker les alertes dans la base de données (table alerts)
      // Pour l'instant, on retourne un historique vide
      return {
        alerts: [],
        total: 0,
      };
    } catch (error) {
      console.error('Erreur récupération historique:', error);
      throw new Error(`Erreur historique: ${error.message}`);
    }
  }
}

module.exports = new AlertService();

