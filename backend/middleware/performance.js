const performanceService = require('../services/performance_service');

/**
 * Middleware d'optimisation de performance
 * 
 * - Compression des réponses
 * - Cache headers
 * - Rate limiting (déjà dans server.js)
 */

/**
 * Middleware de compression (à utiliser avec compression)
 * @param {Object} req - Request
 * @param {Object} res - Response
 * @param {Function} next - Next middleware
 */
function compressionMiddleware(req, res, next) {
  // Compression déjà gérée par nginx en production
  // Ajouter des headers de cache pour les réponses statiques
  if (req.path.startsWith('/uploads') || req.path.startsWith('/static')) {
    res.setHeader('Cache-Control', 'public, max-age=31536000'); // 1 an
  }
  next();
}

/**
 * Middleware de cache pour les requêtes GET
 * @param {string} cacheKey - Clé de cache (optionnel, auto-généré si non fourni)
 * @param {number} ttl - Time to live en ms
 */
function cacheMiddleware(cacheKey = null, ttl = 300000) {
  return async (req, res, next) => {
    // Seulement pour les requêtes GET
    if (req.method !== 'GET') {
      return next();
    }

    const key = cacheKey || `cache:${req.path}:${JSON.stringify(req.query)}`;
    
    try {
      const cached = await performanceService.getCached(
        key,
        async () => {
          // Stocker la fonction send originale
          const originalSend = res.send.bind(res);
          
          // Override res.send pour capturer la réponse
          res.send = function(data) {
            originalSend(data);
            return data;
          };
          
          // Attendre que la route termine
          await new Promise((resolve) => {
            res.on('finish', resolve);
          });
        },
        ttl
      );

      if (cached && !res.headersSent) {
        res.setHeader('X-Cache', 'HIT');
        return res.json(cached);
      }

      res.setHeader('X-Cache', 'MISS');
      next();
    } catch (error) {
      console.error('Erreur cache middleware:', error);
      next();
    }
  };
}

/**
 * Middleware de nettoyage automatique du cache
 */
function setupCacheCleanup() {
  // Nettoyer le cache expiré toutes les 10 minutes
  setInterval(() => {
    performanceService.cleanExpiredCache();
  }, 600000);
}

module.exports = {
  compressionMiddleware,
  cacheMiddleware,
  setupCacheCleanup
};

