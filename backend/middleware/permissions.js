const { dbGet } = require('../config/database');

/**
 * Middleware de vérification des permissions
 * @param {string} resource - Ressource à accéder
 * @param {string} action - Action à effectuer (create, read, update, delete)
 */
const checkPermission = (resource, action) => {
  return async (req, res, next) => {
    try {
      const user = req.user;
      
      if (!user || !user.role) {
        return res.status(401).json({ error: 'Non authentifié' });
      }

      // Admin a tous les droits
      if (user.role === 'admin') {
        return next();
      }

      // Vérifier la permission
      const permission = await dbGet(
        'SELECT * FROM permissions WHERE role = ? AND resource = ? AND action = ? AND allowed = 1',
        [user.role, resource, action]
      );

      // Vérifier permission générique (*)
      if (!permission) {
        const wildcard = await dbGet(
          'SELECT * FROM permissions WHERE role = ? AND resource = ? AND action = ? AND allowed = 1',
          [user.role, '*', '*']
        );
        if (!wildcard) {
          return res.status(403).json({ error: 'Permission refusée' });
        }
      }

      next();
    } catch (error) {
      console.error('Erreur vérification permission:', error);
      res.status(500).json({ error: 'Erreur lors de la vérification des permissions' });
    }
  };
};

/**
 * Middleware d'audit (journalisation)
 */
const auditLog = (action, resource) => {
  return async (req, res, next) => {
    const originalSend = res.send;
    
    res.send = function(data) {
      // Logger après la réponse
      if (req.user) {
        const ipAddress = req.ip || req.headers['x-forwarded-for'] || req.socket.remoteAddress;
        const userAgent = req.headers['user-agent'];
        
        const { dbRun } = require('../config/database');
        dbRun(
          `INSERT INTO audit_log (user_id, action, resource, resource_id, details, ip_address, user_agent)
           VALUES (?, ?, ?, ?, ?, ?, ?)`,
          [
            req.user.id,
            action,
            resource,
            req.params.id || req.body.id || null,
            JSON.stringify({ method: req.method, url: req.url }),
            ipAddress,
            userAgent
          ]
        ).catch(err => console.error('Erreur audit log:', err));
      }
      
      originalSend.call(this, data);
    };
    
    next();
  };
};

module.exports = {
  checkPermission,
  auditLog,
};

