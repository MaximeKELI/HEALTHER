const client = require('prom-client');

// Créer un Registry pour les métriques
const register = new client.Registry();

// Ajouter les métriques par défaut (CPU, mémoire, etc.)
client.collectDefaultMetrics({ register });

// Métriques personnalisées
const httpRequestDuration = new client.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Durée des requêtes HTTP en secondes',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [0.1, 0.5, 1, 2, 5, 10],
});

const httpRequestTotal = new client.Counter({
  name: 'http_requests_total',
  help: 'Nombre total de requêtes HTTP',
  labelNames: ['method', 'route', 'status_code'],
});

const diagnosticsCreated = new client.Counter({
  name: 'diagnostics_created_total',
  help: 'Nombre total de diagnostics créés',
  labelNames: ['maladie_type', 'statut'],
});

const diagnosticsByRegion = new client.Gauge({
  name: 'diagnostics_by_region',
  help: 'Nombre de diagnostics par région',
  labelNames: ['region'],
});

const activeUsers = new client.Gauge({
  name: 'active_users_total',
  help: 'Nombre d\'utilisateurs actifs',
});

const queueSize = new client.Gauge({
  name: 'queue_size',
  help: 'Taille de la file d\'attente',
  labelNames: ['queue_name'],
});

register.registerMetric(httpRequestDuration);
register.registerMetric(httpRequestTotal);
register.registerMetric(diagnosticsCreated);
register.registerMetric(diagnosticsByRegion);
register.registerMetric(activeUsers);
register.registerMetric(queueSize);

// Middleware pour enregistrer les métriques HTTP
function monitoringMiddleware(req, res, next) {
  const start = Date.now();
  
  res.on('finish', () => {
    const duration = (Date.now() - start) / 1000;
    const route = req.route ? req.route.path : req.path;
    
    httpRequestDuration.observe(
      { method: req.method, route, status_code: res.statusCode },
      duration
    );
    
    httpRequestTotal.inc({
      method: req.method,
      route,
      status_code: res.statusCode,
    });
  });
  
  next();
}

/**
 * Obtenir les métriques au format Prometheus
 */
function getMetrics() {
  return register.metrics();
}

/**
 * Enregistrer la création d'un diagnostic
 */
function recordDiagnosticCreated(maladieType, statut, region) {
  diagnosticsCreated.inc({ maladie_type: maladieType, statut });
  
  // Mettre à jour le compteur par région
  diagnosticsByRegion.inc({ region: region || 'unknown' });
}

module.exports = {
  monitoringMiddleware,
  getMetrics,
  recordDiagnosticCreated,
  register,
};
