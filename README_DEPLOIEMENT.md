# 🚀 Guide de Déploiement Production - HEALTHER

Ce guide couvre le déploiement de HEALTHER en production avec Docker, CI/CD et optimisations.

---

## 📦 Déploiement avec Docker

### 1. Build de l'Image

```bash
docker build -t healther-backend .
```

### 2. Lancement avec Docker Compose

```bash
# Développement
docker-compose up -d

# Production
docker-compose -f docker-compose.prod.yml up -d
```

### 3. Vérification

```bash
# Vérifier les conteneurs
docker ps

# Vérifier les logs
docker logs healther-backend

# Health check
curl http://localhost:3000/health
```

---

## 🔄 CI/CD avec GitHub Actions

Le pipeline CI/CD est configuré dans `.github/workflows/ci.yml`

**Étapes automatiques :**
1. ✅ Tests (linter, tests unitaires)
2. ✅ Build Docker image
3. ✅ Push vers Docker Hub
4. ✅ Déploiement automatique (à configurer)

**Configuration requise :**
- Secrets GitHub : `DOCKER_USERNAME`, `DOCKER_PASSWORD`

---

## ⚡ Optimisations de Performance

### Cache

Le service `performance_service.js` implémente :
- ✅ Cache intelligent avec expiration
- ✅ Invalidation automatique
- ✅ Nettoyage du cache expiré

### Compression

- ✅ Compression gzip (nginx)
- ✅ Headers Cache-Control
- ✅ Compression des réponses API

### Pagination

- ✅ Pagination optimisée avec LIMIT/OFFSET
- ✅ Requêtes SQL optimisées
- ✅ Index de base de données

---

## 🧪 Tests Automatisés

### Configuration

Tests configurés avec Jest dans `backend/jest.config.js`

### Lancer les Tests

```bash
cd backend

# Tous les tests
npm test

# Tests en mode watch
npm run test:watch

# Avec couverture
npm run test:coverage
```

### Tests Disponibles

- ✅ `tests/contact_tracing.test.js` - Tests Contact Tracing
- ✅ `tests/medication.test.js` - Tests Médications

**À compléter :** Ajouter plus de tests pour couverture complète

---

## 📊 Monitoring Production

### Health Check

Endpoint : `GET /health`

### Métriques Prometheus

Endpoint : `GET /metrics`

### Logs

```bash
# Docker logs
docker logs -f healther-backend

# Logs avec rotation
# Configurer avec logrotate ou journald
```

---

## 🔒 Sécurité Production

### Checklist

- [ ] Variables d'environnement sécurisées (`.env` non commité)
- [ ] HTTPS configuré (SSL/TLS)
- [ ] Rate limiting activé
- [ ] Helmet.js activé (déjà dans server.js)
- [ ] CORS configuré correctement
- [ ] JWT secret fort (≠ valeur par défaut)
- [ ] Base de données sécurisée
- [ ] Backups automatiques configurés

---

## 📈 Scaling

### Horizontal Scaling

1. **Load Balancer** : Nginx déjà configuré
2. **Multi-instances** : Déployer plusieurs conteneurs backend
3. **Redis** : Cache partagé entre instances

### Vertical Scaling

- Augmenter ressources CPU/RAM du conteneur
- Optimiser les requêtes SQL
- Utiliser PostgreSQL au lieu de SQLite (production)

---

## 🔄 Migrations Base de Données

Pour les mises à jour de schéma :

```bash
cd backend
npm run init-db
```

**Note :** En production, utiliser des migrations versionnées plutôt que `init-db.js`

---

## 📝 Checklist Déploiement

### Pré-déploiement

- [ ] Tests passent
- [ ] Build Docker réussi
- [ ] Variables d'environnement configurées
- [ ] SSL/HTTPS configuré
- [ ] Backups configurés

### Déploiement

- [ ] Conteneurs démarrés
- [ ] Health check OK
- [ ] Logs sans erreur
- [ ] Base de données initialisée

### Post-déploiement

- [ ] API fonctionnelle
- [ ] Monitoring actif
- [ ] Alertes configurées
- [ ] Documentation mise à jour

---

*Dernière mise à jour : Janvier 2025*

