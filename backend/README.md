# M.A.D.E Backend API

Backend Node.js pour le projet M.A.D.E (Modèle d'Aide au Diagnostic et à l'Épidémiosurveillance).

## Installation

```bash
npm install
```

## Configuration

1. Copiez `.env.example` vers `.env`:
```bash
cp .env.example .env
```

2. Configurez les variables d'environnement dans `.env`:
```
PORT=3000
NODE_ENV=development
DB_PATH=./data/made.db
UPLOAD_DIR=./uploads
```

## Initialisation de la base de données

```bash
npm run init-db
```

Cela créera la base de données SQLite avec toutes les tables nécessaires.

## Démarrage

Mode développement (avec nodemon):
```bash
npm run dev
```

Mode production:
```bash
npm start
```

Le serveur sera accessible sur `http://localhost:3000`

## Endpoints API

### Health Check
- `GET /health` - Vérification de l'état du serveur

### Diagnostics
- `POST /api/diagnostics` - Créer un nouveau diagnostic
- `GET /api/diagnostics` - Liste des diagnostics (avec filtres)
- `GET /api/diagnostics/:id` - Obtenir un diagnostic spécifique

### Dashboard
- `GET /api/dashboard/stats` - Statistiques générales
- `GET /api/dashboard/epidemics` - Clusters épidémiques actifs
- `GET /api/dashboard/map` - Carte des cas géolocalisés

### Utilisateurs
- `POST /api/users/register` - Inscription d'un nouvel utilisateur
- `POST /api/users/login` - Authentification
- `GET /api/users` - Liste des utilisateurs
- `GET /api/users/:id` - Obtenir un utilisateur spécifique

## Structure de la base de données

- **users**: Utilisateurs (agents de santé)
- **diagnostics**: Diagnostics effectués
- **epidemics**: Clusters épidémiques détectés
- **daily_stats**: Statistiques journalières agrégées

## Notes

- L'authentification est simplifiée (hash de mot de passe en clair pour le POC)
- Pour la production, utilisez bcrypt ou un système JWT approprié
- Les images peuvent être envoyées en base64 ou stockées dans le système de fichiers


