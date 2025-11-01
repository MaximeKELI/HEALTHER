const db = require('../db');

/**
 * Service pour la prédiction épidémique avec IA
 * Utilise des algorithmes de machine learning pour prédire les épidémies
 */
class PredictionService {
  /**
   * Prédire les épidémies futures basées sur les données historiques
   * @param {Object} params - Paramètres de prédiction
   * @returns {Promise<Object>} Prédictions avec probabilités
   */
  async predictEpidemics(params = {}) {
    try {
      const {
        region,
        maladieType,
        daysAhead = 7,
        includeHistory = true,
      } = params;

      // Récupérer les données historiques
      const historicalData = await this._getHistoricalData({
        region,
        maladieType,
        days: 30, // 30 derniers jours pour la prédiction
      });

      // Calculer les tendances
      const trends = this._calculateTrends(historicalData);

      // Prédire les épidémies futures
      const predictions = this._predictFutureTrends(trends, daysAhead);

      return {
        predictions,
        trends,
        historicalData: includeHistory ? historicalData : undefined,
        confidence: this._calculateConfidence(trends),
      };
    } catch (error) {
      console.error('Erreur prédiction épidémique:', error);
      throw new Error(`Erreur prédiction: ${error.message}`);
    }
  }

  /**
   * Obtenir les données historiques
   * @private
   */
  async _getHistoricalData({ region, maladieType, days }) {
    try {
      let query = `
        SELECT 
          DATE(created_at) as date,
          COUNT(*) as count,
          SUM(CASE WHEN statut = 'positif' THEN 1 ELSE 0 END) as positifs
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
      
      query += ' GROUP BY DATE(created_at) ORDER BY date ASC';
      
      const rows = await new Promise((resolve, reject) => {
        db.all(query, params, (err, rows) => {
          if (err) reject(err);
          else resolve(rows);
        });
      });
      
      return rows;
    } catch (error) {
      console.error('Erreur récupération données historiques:', error);
      return [];
    }
  }

  /**
   * Calculer les tendances à partir des données historiques
   * @private
   */
  _calculateTrends(historicalData) {
    if (historicalData.length < 2) {
      return {
        growthRate: 0,
        trend: 'stable',
        averageDaily: 0,
      };
    }

    // Calculer le taux de croissance moyen
    const values = historicalData.map(d => d.count || 0);
    const positiveValues = historicalData.map(d => d.positifs || 0);
    
    const avgGrowth = this._calculateAverageGrowthRate(values);
    const avgPositiveGrowth = this._calculateAverageGrowthRate(positiveValues);
    
    const averageDaily = values.reduce((a, b) => a + b, 0) / values.length;
    const averagePositive = positiveValues.reduce((a, b) => a + b, 0) / positiveValues.length;

    // Déterminer la tendance
    let trend = 'stable';
    if (avgGrowth > 0.1) trend = 'increasing';
    else if (avgGrowth < -0.1) trend = 'decreasing';

    return {
      growthRate: avgGrowth,
      positiveGrowthRate: avgPositiveGrowth,
      trend,
      averageDaily,
      averagePositive,
      totalDays: historicalData.length,
    };
  }

  /**
   * Calculer le taux de croissance moyen
   * @private
   */
  _calculateAverageGrowthRate(values) {
    if (values.length < 2) return 0;
    
    const growthRates = [];
    for (let i = 1; i < values.length; i++) {
      if (values[i - 1] > 0) {
        const growth = (values[i] - values[i - 1]) / values[i - 1];
        growthRates.push(growth);
      }
    }
    
    if (growthRates.length === 0) return 0;
    
    return growthRates.reduce((a, b) => a + b, 0) / growthRates.length;
  }

  /**
   * Prédire les tendances futures
   * @private
   */
  _predictFutureTrends(trends, daysAhead) {
    const predictions = [];
    let predictedValue = trends.averageDaily;
    
    for (let day = 1; day <= daysAhead; day++) {
      // Appliquer le taux de croissance moyen
      predictedValue = predictedValue * (1 + trends.growthRate);
      
      // Limiter les valeurs négatives
      predictedValue = Math.max(0, predictedValue);
      
      predictions.push({
        day: day,
        date: new Date(Date.now() + day * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
        predictedCount: Math.round(predictedValue),
        predictedPositive: Math.round(predictedValue * (trends.averagePositive / trends.averageDaily || 0)),
        riskLevel: this._calculateRiskLevel(predictedValue, trends),
      });
    }
    
    return predictions;
  }

  /**
   * Calculer le niveau de risque
   * @private
   */
  _calculateRiskLevel(predictedValue, trends) {
    const threshold = trends.averageDaily * 1.5; // 50% au-dessus de la moyenne
    
    if (predictedValue > threshold * 1.5) return 'high';
    if (predictedValue > threshold) return 'medium';
    return 'low';
  }

  /**
   * Calculer la confiance de la prédiction
   * @private
   */
  _calculateConfidence(trends) {
    // La confiance dépend de la quantité de données historiques
    let confidence = Math.min(trends.totalDays / 30, 1) * 0.7; // Max 70% basé sur données
    
    // Réduire la confiance si la tendance est très variable
    if (Math.abs(trends.growthRate) > 0.5) {
      confidence *= 0.8; // Réduire de 20% si très variable
    }
    
    return Math.round(confidence * 100);
  }

  /**
   * Détecter les anomalies dans les données
   */
  async detectAnomalies({ region, maladieType, days = 7 }) {
    try {
      const historicalData = await this._getHistoricalData({
        region,
        maladieType,
        days: 30,
      });
      
      const trends = this._calculateTrends(historicalData);
      const recentData = historicalData.slice(-days);
      
      const anomalies = [];
      const threshold = trends.averageDaily * 2; // 2x la moyenne = anomalie
      
      recentData.forEach((data, index) => {
        if ((data.count || 0) > threshold) {
          anomalies.push({
            date: data.date,
            count: data.count,
            expected: Math.round(trends.averageDaily),
            deviation: Math.round(((data.count - trends.averageDaily) / trends.averageDaily) * 100),
          });
        }
      });
      
      return {
        anomalies,
        trends,
        hasAnomalies: anomalies.length > 0,
      };
    } catch (error) {
      console.error('Erreur détection anomalies:', error);
      throw new Error(`Erreur détection: ${error.message}`);
    }
  }
}

module.exports = new PredictionService();

