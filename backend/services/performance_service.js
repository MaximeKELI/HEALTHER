/**
 * Service d'Optimisation de Performance
 * 
 * Fonctionnalités :
 * - Cache intelligent
 * - Compression des réponses
 * - Pagination optimisée
 * - Lazy loading
 * - Query optimization
 */

const { dbAll, dbGet } = require('../config/database');

class PerformanceService {
  constructor() {
    this.cache = new Map();
    this.cacheExpiry = new Map();
    this.cacheTTL = 300000; // 5 minutes par défaut
  }

  /**
   * Cache intelligent avec expiration
   * @param {string} key - Clé de cache
   * @param {Function} fetchFn - Fonction pour récupérer les données si non en cache
   * @param {number} ttl - Time to live en ms (optionnel)
   * @returns {Promise<any>} Données en cache ou récupérées
   */
  async getCached(key, fetchFn, ttl = null) {
    const expiry = this.cacheExpiry.get(key);
    const now = Date.now();

    // Vérifier si le cache est valide
    if (this.cache.has(key) && expiry && now < expiry) {
      return this.cache.get(key);
    }

    // Récupérer les données
    const data = await fetchFn();

    // Mettre en cache
    this.cache.set(key, data);
    this.cacheExpiry.set(key, now + (ttl || this.cacheTTL));

    return data;
  }

  /**
   * Invalider le cache pour une clé
   * @param {string} key - Clé de cache
   */
  invalidateCache(key) {
    this.cache.delete(key);
    this.cacheExpiry.delete(key);
  }

  /**
   * Nettoyer le cache expiré
   */
  cleanExpiredCache() {
    const now = Date.now();
    for (const [key, expiry] of this.cacheExpiry.entries()) {
      if (now >= expiry) {
        this.cache.delete(key);
        this.cacheExpiry.delete(key);
      }
    }
  }

  /**
   * Optimiser une requête SQL avec pagination
   * @param {string} baseQuery - Requête SQL de base
   * @param {Array} params - Paramètres SQL
   * @param {number} page - Numéro de page
   * @param {number} pageSize - Taille de page
   * @returns {Promise<Object>} Données paginées optimisées
   */
  async paginatedQuery(baseQuery, params, page = 1, pageSize = 20) {
    const offset = (page - 1) * pageSize;
    const limit = pageSize;

    // Compter le total
    const countQuery = `SELECT COUNT(*) as total FROM (${baseQuery}) as subquery`;
    const countResult = await dbGet(countQuery, params);
    const total = countResult?.total || 0;

    // Requête paginée optimisée
    const paginatedQuery = `${baseQuery} LIMIT ? OFFSET ?`;
    const paginatedParams = [...params, limit, offset];

    const data = await dbAll(paginatedQuery, paginatedParams);

    return {
      data,
      pagination: {
        page,
        pageSize,
        total,
        totalPages: Math.ceil(total / pageSize),
        hasNext: page * pageSize < total,
        hasPrev: page > 1
      }
    };
  }

  /**
   * Optimiser les requêtes de statistiques avec cache
   * @param {string} cacheKey - Clé de cache
   * @param {Function} queryFn - Fonction de requête
   * @returns {Promise<Object>} Statistiques optimisées
   */
  async getOptimizedStats(cacheKey, queryFn) {
    return this.getCached(
      `stats:${cacheKey}`,
      queryFn,
      60000 // 1 minute pour les stats
    );
  }
}

module.exports = new PerformanceService();

