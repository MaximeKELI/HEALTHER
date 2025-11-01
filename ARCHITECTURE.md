# 🏗️ Architecture du Projet M.A.D.E

## Vue d'Ensemble

M.A.D.E est une application mobile avec backend API pour l'aide au diagnostic et la surveillance épidémiologique.

```
┌─────────────────────────────────────────────────────────┐
│                    Application Flutter                   │
│  ┌─────────────┐  ┌──────────────┐  ┌───────────────┐  │
│  │   Screens   │  │  Providers   │  │   Services    │  │
│  │             │  │              │  │               │  │
│  │ - Login     │  │ - Auth       │  │ - API Service │  │
│  │ - Home      │  │ - Diagnostic │  │ - Camera      │  │
│  │ - Diagnostic│  │              │  │ - Location    │  │
│  │ - History   │  │              │  │               │  │
│  │ - Dashboard │  │              │  │               │  │
│  └─────────────┘  └──────────────┘  └───────────────┘  │
└─────────────────────────────────────────────────────────┘
                         │ HTTP/REST
                         ▼
┌─────────────────────────────────────────────────────────┐
│                   Backend Node.js                        │
│  ┌─────────────┐  ┌──────────────┐  ┌───────────────┐  │
│  │   Routes    │  │   Services   │  │  Middleware   │  │
│  │             │  │              │  │               │  │
│  │ - Users     │  │ - Database   │  │ - CORS        │  │
│  │ - Diagnostics│ │ - Auth       │  │ - Body Parser │  │
│  │ - Dashboard │  │              │  │ - Error Handle│  │
│  └─────────────┘  └──────────────┘  └───────────────┘  │
└─────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────┐
│                    SQLite Database                        │
│  ┌─────────────┐  ┌──────────────┐  ┌───────────────┐  │
│  │   users     │  │  diagnostics │  │   epidemics   │  │
│  │             │  │              │  │               │  │
│  │ - id        │  │ - id         │  │ - id          │  │
│  │ - username  │  │ - user_id    │  │ - region      │  │
│  │ - email     │  │ - maladie    │  │ - maladie     │  │
│  │ - role      │  │ - statut     │  │ - nombre_cas  │  │
│  │             │  │ - lat/long   │  │ - niveau_alerte│ │
│  └─────────────┘  └──────────────┘  └───────────────┘  │
│                                                           │
│  ┌─────────────┐                                         │
│  │ daily_stats │                                         │
│  │             │                                         │
│  │ - date      │                                         │
│  │ - region    │                                         │
│  │ - maladie   │                                         │
│  │ - cas_*     │                                         │
│  └─────────────┘                                         │
└─────────────────────────────────────────────────────────┘
```

## Frontend Flutter

### Structure

```
lib/
├── main.dart                    # Point d'entrée
├── models/                      # Modèles de données
│   ├── user.dart
│   ├── diagnostic.dart
│   └── epidemic.dart
├── screens/                     # Écrans de l'application
│   ├── login_screen.dart
│   ├── home_screen.dart
│   ├── diagnostic_screen.dart
│   ├── history_screen.dart
│   └── dashboard_screen.dart
├── services/                    # Services métier
│   ├── api_service.dart         # Communication API
│   ├── camera_service.dart      # Gestion caméra
│   └── location_service.dart    # Géolocalisation
└── providers/                   # Gestion d'état (Provider)
    ├── auth_provider.dart
    └── diagnostic_provider.dart
```

### Flux de Données

```
User Action → Screen → Provider → Service → API → Backend
                    ↓
              State Update → UI Rebuild
```

### Gestion d'État (Provider)

- **AuthProvider** : Gestion de l'authentification utilisateur
- **DiagnosticProvider** : Gestion des diagnostics et analyses

## Backend Node.js

### Structure

```
backend/
├── server.js                   # Point d'entrée
├── config/
│   └── database.js             # Configuration SQLite
├── routes/
│   ├── users.js                # Routes utilisateurs
│   ├── diagnostics.js           # Routes diagnostics
│   └── dashboard.js            # Routes dashboard
├── scripts/
│   ├── init-db.js              # Initialisation BDD
│   └── create-user.js          # Création utilisateur
├── data/                       # Base de données SQLite
└── uploads/                    # Fichiers uploadés
```

### Routes API

#### `/api/users`
- `POST /register` - Inscription
- `POST /login` - Authentification
- `GET /` - Liste des utilisateurs
- `GET /:id` - Utilisateur spécifique

#### `/api/diagnostics`
- `POST /` - Créer un diagnostic
- `GET /` - Liste des diagnostics (filtres: user_id, maladie_type, region, dates)
- `GET /:id` - Diagnostic spécifique

#### `/api/dashboard`
- `GET /stats` - Statistiques globales
- `GET /epidemics` - Clusters épidémiques actifs
- `GET /map` - Carte des cas géolocalisés

## Base de Données SQLite

### Schéma

#### Table `users`
- `id` (INTEGER PRIMARY KEY)
- `username` (TEXT UNIQUE)
- `email` (TEXT UNIQUE)
- `password_hash` (TEXT)
- `role` (TEXT) : 'agent', 'admin'
- `nom`, `prenom` (TEXT)
- `centre_sante` (TEXT)
- `created_at` (DATETIME)

#### Table `diagnostics`
- `id` (INTEGER PRIMARY KEY)
- `user_id` (INTEGER) → users.id
- `maladie_type` (TEXT) : 'paludisme', 'typhoide', 'mixte'
- `image_base64` (TEXT)
- `resultat_ia` (JSON)
- `confiance` (REAL)
- `statut` (TEXT) : 'positif', 'negatif', 'incertain'
- `quantite_parasites` (REAL)
- `commentaires` (TEXT)
- `latitude`, `longitude` (REAL)
- `adresse`, `region`, `prefecture` (TEXT)
- `created_at` (DATETIME)

#### Table `epidemics`
- `id` (INTEGER PRIMARY KEY)
- `region` (TEXT)
- `prefecture` (TEXT)
- `maladie_type` (TEXT)
- `nombre_cas` (INTEGER)
- `date_debut` (DATE)
- `date_fin` (DATE)
- `statut` (TEXT) : 'actif', 'resolu', 'surveille'
- `niveau_alerte` (TEXT) : 'vert', 'jaune', 'orange', 'rouge'
- `actions_prises` (TEXT)
- `created_at` (DATETIME)

#### Table `daily_stats`
- `id` (INTEGER PRIMARY KEY)
- `date` (DATE)
- `region` (TEXT)
- `maladie_type` (TEXT)
- `cas_positifs` (INTEGER)
- `cas_negatifs` (INTEGER)
- `cas_totaux` (INTEGER)
- `taux_positivite` (REAL)
- UNIQUE(date, region, maladie_type)

## Flux de Diagnostic

```
1. Utilisateur prend une photo
   ↓
2. Image convertie en base64
   ↓
3. Analyse IA (simulation pour le POC)
   ↓
4. Récupération géolocalisation
   ↓
5. Création du diagnostic via API
   ↓
6. Sauvegarde en base de données
   ↓
7. Mise à jour des statistiques quotidiennes
   ↓
8. Vérification des clusters épidémiques
   ↓
9. Notification si cluster détecté
```

## Détection des Clusters Épidémiques

Algorithme simple (à améliorer) :
- Compter les cas positifs sur 7 jours dans une région
- Si ≥ 10 cas : créer/mettre à jour un cluster
- Niveau d'alerte basé sur le nombre de cas :
  - Vert : < 10 cas
  - Jaune : 10-29 cas
  - Orange : 30-49 cas
  - Rouge : ≥ 50 cas

## Sécurité (POC)

⚠️ **Note** : Cette version est un POC. Pour la production :

1. **Authentification** : Implémenter JWT + bcrypt
2. **HTTPS** : Utiliser HTTPS en production
3. **Validation** : Ajouter validation des données d'entrée
4. **Rate Limiting** : Limiter les requêtes par utilisateur
5. **CORS** : Configurer CORS de manière restrictive
6. **Base de données** : Migrer vers PostgreSQL avec chiffrement
7. **Logs** : Implémenter un système de logs robuste

## Améliorations Futures

1. **IA Réelle** : Intégrer un modèle d'IA réel (TensorFlow Lite, ONNX)
2. **Mode Hors Ligne** : Synchronisation lorsque connexion disponible
3. **Notifications Push** : Alertes pour clusters épidémiques
4. **Dashboard Web** : Interface web pour le ministère de la santé
5. **Export de Données** : Export CSV/Excel pour analyses externes
6. **Authentification Biométrique** : Pour sécurité renforcée
7. **Multi-langue** : Support français/anglais/langues locales


