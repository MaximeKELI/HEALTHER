# 🚀 Guide de Mise en Production - M.A.D.E

## ✅ Modifications pour Production

### 1. Authentification Sécurisée ✅

- **Bcrypt** : Hashage des mots de passe (10 salt rounds)
- **JWT** : Tokens d'authentification sécurisés (24h expiration)
- Validation des mots de passe (minimum 6 caractères)

### 2. Service ML Réel ✅

- **Service ML Backend** : Prêt pour intégration de modèle réel
- **API ML** : `/api/ml/analyze` pour analyse d'images
- **Preprocessing** : Optimisation des images avant analyse

### 3. Plus de Simulation ✅

- **Suppression de la simulation** : Plus de résultats aléatoires
- **Analyse réelle** : Appel au backend ML pour vraie analyse
- **Erreurs gérées** : Gestion appropriée des erreurs ML

## 📋 Checklist Pré-Production

### Backend

- [ ] Installer les dépendances : `npm install`
- [ ] Configurer `.env` avec :
  - `JWT_SECRET` (clé secrète forte)
  - `NODE_ENV=production`
  - `DB_PATH` (chemin vers base de données production)
- [ ] Intégrer un modèle ML réel (voir `INTEGRATION_ML.md`)
- [ ] Configurer HTTPS
- [ ] Configurer CORS pour production
- [ ] Activer rate limiting
- [ ] Configurer logging
- [ ] Tests de charge

### Frontend

- [ ] Configurer l'URL de l'API selon l'environnement
- [ ] Gérer l'authentification JWT
- [ ] Implémenter refresh tokens
- [ ] Gérer les erreurs réseau
- [ ] Optimiser les images avant envoi
- [ ] Tests sur appareils réels

### Base de Données

- [ ] Migrer vers PostgreSQL (ou autre BDD production)
- [ ] Configurer backups automatiques
- [ ] Optimiser les index
- [ ] Tests de performance

## 🔐 Sécurité

### Variables d'Environnement

```env
NODE_ENV=production
PORT=3000
JWT_SECRET=votre-cle-secrete-tres-longue-et-aleatoire
DB_PATH=/var/lib/made/made.db
UPLOAD_DIR=/var/lib/made/uploads
MODEL_PATH=/var/lib/made/models/malaria_model.json
```

### HTTPS

Utiliser un reverse proxy (Nginx) avec SSL :

```nginx
server {
    listen 443 ssl;
    server_name api.made.tg;
    
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

### CORS Production

```javascript
// Dans server.js
const cors = require('cors');

app.use(cors({
  origin: ['https://app.made.tg', 'https://made.tg'],
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
}));
```

### Rate Limiting

```bash
npm install express-rate-limit
```

```javascript
const rateLimit = require('express-rate-limit');

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // limite chaque IP à 100 requêtes par windowMs
});

app.use('/api/', limiter);
```

## 🧠 Intégration Modèle ML

Voir `INTEGRATION_ML.md` pour les détails complets.

**Options recommandées** :
1. **Service Python séparé** (Recommandé)
   - Flask/FastAPI
   - TensorFlow/Keras
   - Docker

2. **TensorFlow.js**
   - Node.js natif
   - Modèle converti
   - Plus simple à déployer

3. **API Cloud**
   - Google Vision API
   - AWS Rekognition
   - Azure Cognitive Services

## 📊 Monitoring

### Logs

```javascript
const winston = require('winston');

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.json(),
  transports: [
    new winston.transports.File({ filename: 'error.log', level: 'error' }),
    new winston.transports.File({ filename: 'combined.log' })
  ]
});

if (process.env.NODE_ENV !== 'production') {
  logger.add(new winston.transports.Console({
    format: winston.format.simple()
  }));
}
```

### Health Checks

- `/health` : État général du serveur
- `/api/ml/health` : État du service ML

### Métriques

- Nombre de diagnostics par jour
- Taux de succès des analyses ML
- Temps de réponse moyen
- Erreurs par type

## 🚀 Déploiement

### Backend

```bash
# PM2 pour gestion des processus
npm install -g pm2

# Démarrer l'application
pm2 start server.js --name made-backend

# Sauvegarder la configuration
pm2 save
pm2 startup
```

### Frontend Flutter

```bash
# Build Android
flutter build apk --release

# Build iOS
flutter build ios --release

# Build Web
flutter build web --release
```

## 📝 Notes Importantes

1. **Modèle ML** : Intégrer un vrai modèle avant production
2. **Validation médicale** : Obtenir validation des professionnels
3. **Réglementation** : Respecter les lois locales sur les données médicales
4. **Tests** : Tests exhaustifs avant déploiement
5. **Backup** : Système de backup automatique
6. **Monitoring** : Surveillance continue en production

## 🔄 Mise à Jour

1. Sauvegarder la base de données
2. Tester en staging
3. Déployer progressivement
4. Monitorer les erreurs
5. Rollback si nécessaire

