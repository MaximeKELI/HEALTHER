<div align="center">

# 🏥 <span style="color:#2563eb;font-family:'Italianno',cursive;font-size:2.5em;animation: pulse 2s infinite">HEALTHER</span>

**Plateforme de Diagnostic Médical Intelligente pour la Santé Publique**

[![Version](https://img.shields.io/badge/Version-1.0.0-blue.svg?style=for-the-badge&logo=version)](https://github.com/votre-repo/HEALTHER)
[![Backend](https://img.shields.io/badge/Backend-Node.js-339933?style=for-the-badge&logo=node.js)](https://nodejs.org/)
[![Frontend](https://img.shields.io/badge/Frontend-Flutter-02569B?style=for-the-badge&logo=flutter)](https://flutter.dev/)
[![Database](https://img.shields.io/badge/Database-SQLite-003B57?style=for-the-badge&logo=sqlite)](https://www.sqlite.org/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](LICENSE)
[![Status](https://img.shields.io/badge/Status-Active-success.svg?style=for-the-badge)](https://github.com/votre-repo/HEALTHER)

![Build](https://img.shields.io/github/workflow/status/votre-repo/HEALTHER/CI?style=for-the-badge)
![Issues](https://img.shields.io/github/issues/votre-repo/HEALTHER?style=for-the-badge&color=blue)
![Pull Requests](https://img.shields.io/github/issues-pr/votre-repo/HEALTHER?style=for-the-badge&color=green)
![Code Size](https://img.shields.io/github/languages/code-size/votre-repo/HEALTHER?style=for-the-badge)

[![Stars](https://img.shields.io/github/stars/votre-repo/HEALTHER?style=social)](https://github.com/votre-repo/HEALTHER/stargazers)
[![Forks](https://img.shields.io/github/forks/votre-repo/HEALTHER?style=social)](https://github.com/votre-repo/HEALTHER/network/members)
[![Watchers](https://img.shields.io/github/watchers/votre-repo/HEALTHER?style=social)](https://github.com/votre-repo/HEALTHER/watchers)

</div>

---

## 📋 Table des Matières

- [🎯 Vue d'ensemble](#-vue-densemble)
- [✨ Fonctionnalités](#-fonctionnalités)
- [🏗️ Architecture](#️-architecture)
- [🗄️ Modèle de Données](#️-modèle-de-données)
  - [MCD (Modèle Conceptuel de Données)](#mcd-modèle-conceptuel-de-données)
  - [MLD (Modèle Logique de Données)](#mld-modèle-logique-de-données)
- [🛠️ Technologies](#️-technologies)
- [📦 Installation](#-installation)
- [⚙️ Configuration](#️-configuration)
- [🚀 Démarrage](#-démarrage)
- [📱 Utilisation](#-utilisation)
- [🔐 Sécurité](#-sécurité)
- [🤖 IA et ML](#-ia-et-ml)
- [📊 API Documentation](#-api-documentation)
- [🧪 Tests](#-tests)
- [📈 Roadmap](#-roadmap)
- [🤝 Contribution](#-contribution)
- [📄 License](#-license)

---

## 🎯 Vue d'ensemble

**HEALTHER** est une plateforme complète de diagnostic médical assisté par intelligence artificielle, conçue pour améliorer la détection et le suivi des maladies infectieuses (paludisme, typhoïde) dans les régions à faible connectivité.

### Objectifs Principaux

- 🎯 **Diagnostic Rapide** : Analyse d'images microscopiques via IA pour détecter les parasites
- 📍 **Géolocalisation** : Tracking géographique des cas pour surveillance épidémiologique
- 🌐 **Fonctionnement Offline** : Synchronisation automatique dès le retour de la connexion
- 👥 **Multi-Rôles** : Système de permissions pour agents, superviseurs, épidémiologistes et administrateurs
- 📊 **Tableau de Bord** : Visualisation en temps réel des statistiques et tendances
- 🤖 **Chatbot IA** : Assistant conversationnel basé sur Gemini pour guidance et support

---

## ✨ Fonctionnalités

### 🔬 Diagnostic Médical

| Fonctionnalité | Description |
|----------------|-------------|
| 📸 **Capture d'Images** | Prise de photo via caméra ou sélection depuis galerie |
| 🖼️ **Analyse ML** | Détection automatique de parasites (Paludisme, Typhoïde) |
| 📊 **Confiance IA** | Score de confiance pour chaque diagnostic |
| 📝 **Commentaires** | Ajout de notes et annotations sur les diagnostics |
| 📎 **Pièces Jointes** | Upload de fichiers multiples (photos, PDF labo) |
| 🗺️ **Géolocalisation** | Enregistrement automatique de la position GPS |

### 👥 Gestion des Utilisateurs

| Rôle | Permissions |
|------|-------------|
| **Agent** | Créer diagnostics, voir ses propres diagnostics, modifier profil |
| **Superviseur** | Accès à tous les diagnostics, validation, mise à jour |
| **Épidémiologiste** | Accès complet aux données, génération de rapports, dashboard |
| **Admin** | Accès total, gestion utilisateurs, configuration système |

### 📊 Tableau de Bord et Rapports

- 📈 **Statistiques en Temps Réel** : Cas positifs/négatifs, taux de positivité
- 📅 **Filtres Temporels** : Par date, région, préfecture
- 📉 **Courbes Temporelles** : Évolution des cas sur le temps
- 🌍 **Heatmap Géographique** : Visualisation des clusters épidémiques
- 📄 **Export** : Génération de rapports CSV/Excel/PDF

### 🌐 Fonctionnalités Avancées

- 💬 **Chat Contextuel** : Discussions par diagnostic avec mentions
- 📱 **Notifications Push** : Alertes en temps réel (WebSocket)
- 🔔 **Géofencing** : Alertes automatiques lors de dépassement de seuils
- 📋 **Suivi Échantillons** : Traçabilité complète échantillon → labo → résultat
- 🎯 **Campagnes** : Planification d'actions (pulvérisation, sensibilisation)
- 📞 **Rendez-vous** : Gestion des rendez-vous patients avec rappels SMS
- 💊 **Suivi Traitement** : Observance et suivi post-diagnostic
- 🔍 **Recherche Avancée** : Filtres multiples avec pagination
- 📚 **Historique Patient** : Suivi longitudinal des événements médicaux
- ✅ **Tâches** : Système de workflow et assignation de tâches
- 🏥 **Annuaire Santé** : Base des établissements de santé avec ressources

---

## 🏗️ Architecture

### Architecture Globale

```
┌─────────────────────────────────────────────────────────────────┐
│                      Architecture HEALTHER                       │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────┐         ┌─────────────────┐
│   Flutter App   │ ◄─────► │   Backend API   │
│  (Frontend)     │  HTTP   │   (Node.js)     │
│                 │         │                 │
│  • UI/UX        │         │  • Routes       │
│  • State Mgmt   │         │  • Services     │
│  • Offline DB   │         │  • Middleware   │
│  • Socket.IO    │         │  • Socket.IO    │
└─────────────────┘         └─────────────────┘
                                      │
                                      │
                    ┌─────────────────┴─────────────────┐
                    │                                   │
            ┌───────▼────────┐               ┌─────────▼────────┐
            │   SQLite DB    │               │  External APIs  │
            │                │               │                  │
            │  • Users       │               │  • Gemini AI     │
            │  • Diagnostics │               │  • Storage S3    │
            │  • Samples     │               │  • SMS/WhatsApp  │
            │  • Reports     │               │  • FHIR/HL7      │
            └────────────────┘               └──────────────────┘
```

### Structure du Projet

```
HEALTHER/
├── backend/                    # API Backend Node.js
│   ├── config/                 # Configuration
│   ├── data/                   # Base de données SQLite
│   ├── middleware/             # Middleware (auth, permissions)
│   ├── routes/                 # Routes API
│   ├── services/               # Services métier
│   ├── scripts/                # Scripts utilitaires
│   └── server.js               # Point d'entrée
│
├── healther/                   # Application Flutter
│   ├── lib/
│   │   ├── main.dart           # Point d'entrée
│   │   ├── models/             # Modèles de données
│   │   ├── screens/            # Écrans UI
│   │   ├── services/          # Services (API, offline, etc.)
│   │   ├── providers/          # State management (Provider)
│   │   └── widgets/            # Widgets réutilisables
│   ├── assets/                 # Assets (fonts, images)
│   └── pubspec.yaml            # Dépendances Flutter
│
└── README.md                    # Documentation principale
```

### Flux de Données - Diagnostic

```
┌─────────────┐
│   Agent     │
└──────┬──────┘
       │
       │ 1. Capture Image
       ▼
┌─────────────────┐
│  Camera/Gallery │
└──────┬──────────┘
       │
       │ 2. Analyse ML
       ▼
┌─────────────────┐     ┌──────────────────┐
│  ML Service     │────►│  Gemini/Vision   │
│  (TensorFlow)   │     │  API             │
└──────┬──────────┘     └──────────────────┘
       │
       │ 3. Résultat + Géolocalisation
       ▼
┌─────────────────┐
│  Backend API    │
└──────┬──────────┘
       │
       │ 4. Sauvegarde
       ▼
┌─────────────────┐
│   SQLite DB     │
└──────┬──────────┘
       │
       │ 5. Notification (WebSocket)
       ▼
┌─────────────────┐
│  Dashboard/UI   │
└─────────────────┘
```

---

## 🗄️ Modèle de Données

### MCD (Modèle Conceptuel de Données)

Le **MCD** représente les entités principales du système et leurs relations :

```
┌─────────────────────────────────────────────────────────────────────┐
│                    MODÈLE CONCEPTUEL DE DONNÉES (MCD)                │
└─────────────────────────────────────────────────────────────────────┘

┌──────────────┐
│    USERS     │
├──────────────┤
│ id            │──────┐
│ username      │      │
│ email         │      │
│ password_hash │      │
│ role          │      │
│ nom           │      │
│ prenom        │      │
│ centre_sante  │      │
│ profile_pic   │      │
└──────────────┘      │
       │              │
       │              │
       │ 1,N          │
       │              │
       ▼              │
┌──────────────┐      │
│ DIAGNOSTICS  │      │
├──────────────┤      │
│ id            │◄─────┘
│ user_id       │──┐
│ maladie_type  │  │
│ image_path    │  │
│ resultat_ia   │  │
│ confiance     │  │
│ statut        │  │
│ latitude      │  │
│ longitude     │  │
│ region        │  │
└──────────────┘  │
       │          │
       │ 1,N      │
       │          │
       ▼          │
┌──────────────┐  │     ┌──────────────┐
│   SAMPLES    │  │     │ ATTACHMENTS  │
├──────────────┤  │     ├──────────────┤
│ id            │  │     │ id            │
│ diagnostic_id │◄─┘     │ diagnostic_id │◄──┐
│ barcode       │        │ file_path    │   │
│ sample_type   │        │ file_type    │   │
│ lab_id        │        │ mime_type    │   │
│ lab_result    │        └──────────────┘   │
│ status        │                           │
└──────────────┘                           │
       │                                   │
       │                                   │
       ▼                                   │
┌──────────────┐                           │
│ HEALTH_      │                           │
│ CENTERS      │                           │
├──────────────┤                           │
│ id            │                           │
│ name          │                           │
│ type          │                           │
│ latitude      │                           │
│ longitude     │                           │
└──────────────┘                           │
                                           │
┌──────────────┐      ┌──────────────┐     │
│ COMMENTS     │      │  EPIDEMICS  │     │
├──────────────┤      ├──────────────┤     │
│ id            │      │ id            │     │
│ diagnostic_id │◄─────┤ region        │     │
│ user_id       │──┐   │ maladie_type  │     │
│ comment       │  │   │ nombre_cas    │     │
│ parent_id     │  │   │ niveau_alerte │     │
└──────────────┘  │   └──────────────┘     │
                  │                         │
                  │ 1,N                     │
                  │                         │
                  ▼                         │
┌──────────────┐                           │
│ NOTIFICATIONS│                           │
├──────────────┤                           │
│ id            │                           │
│ user_id       │◄─────────────────────────┘
│ type          │
│ title         │
│ message       │
│ read          │
└──────────────┘

┌─────────────────────────────────────┐
│ AUTRES ENTITÉS IMPORTANTES           │
├─────────────────────────────────────┤
│ • CAMPAIGNS (campagnes)              │
│ • APPOINTMENTS (rendez-vous)          │
│ • TREATMENT_FOLLOWUP (suivi)         │
│ • TASKS (tâches)                     │
│ • CHAT_MESSAGES (chat contextuel)    │
│ • CHATBOT_CONVERSATIONS (IA)         │
│ • GEOFENCES (zones d'alerte)          │
│ • REPORTS (rapports)                 │
│ • OFFLINE_QUEUE (sync offline)      │
│ • ML_FEEDBACK (amélioration IA)      │
│ • REFRESH_TOKENS (sécurité)          │
│ • TOTP_SECRETS (2FA)                 │
│ • PATIENT_HISTORY (historique)       │
└─────────────────────────────────────┘
```

#### 📊 Légende des Relations MCD

| Symbole | Signification | Exemple |
|---------|---------------|---------|
| `1,1` | Relation un-à-un (obligatoire) | Un diagnostic a exactement un user |
| `1,N` | Relation un-à-plusieurs | Un user peut avoir plusieurs diagnostics |
| `N,M` | Relation plusieurs-à-plusieurs | Implémentée via table de liaison |
| `(PK)` | Primary Key (Clé Primaire) | Identifiant unique |
| `(FK)` | Foreign Key (Clé Étrangère) | Référence vers une autre table |

#### 🔗 Relations Principales

```
USERS (1) ──────< (N) DIAGNOSTICS
  │                     │
  │                     ├──< (N) SAMPLES
  │                     ├──< (N) COMMENTS
  │                     ├──< (N) ATTACHMENTS
  │                     ├──< (N) APPOINTMENTS
  │                     └──< (N) PATIENT_HISTORY
  │
  ├──< (N) NOTIFICATIONS
  ├──< (N) TASKS (assigned_to)
  ├──< (N) CAMPAIGNS (created_by)
  ├──< (N) REPORTS (generated_by)
  ├──< (N) CHATBOT_CONVERSATIONS
  ├──< (N) AUDIT_LOG
  └──< (1) REFRESH_TOKENS
       (1) TOTP_SECRETS
```

#### 🎯 Cardinalités des Relations

- **USERS → DIAGNOSTICS** : `1,N` (Un utilisateur crée plusieurs diagnostics)
- **DIAGNOSTICS → SAMPLES** : `1,N` (Un diagnostic peut avoir plusieurs échantillons)
- **DIAGNOSTICS → COMMENTS** : `1,N` (Un diagnostic peut avoir plusieurs commentaires)
- **DIAGNOSTICS → ATTACHMENTS** : `1,N` (Un diagnostic peut avoir plusieurs pièces jointes)
- **USERS → NOTIFICATIONS** : `1,N` (Un utilisateur peut recevoir plusieurs notifications)
- **CHATBOT_CONVERSATIONS → CHATBOT_MESSAGES** : `1,N` (Une conversation contient plusieurs messages)
- **DIAGNOSTICS → APPOINTMENTS** : `1,1` ou `1,N` (Un diagnostic peut avoir un ou plusieurs rendez-vous)

---

### MLD (Modèle Logique de Données)

Le **MLD** représente la structure physique des tables dans la base de données SQLite :

#### 🗂️ **Table: `users`**
```sql
CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  username TEXT UNIQUE NOT NULL,
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT 'agent',
  nom TEXT,
  prenom TEXT,
  centre_sante TEXT,
  profile_picture TEXT,
  region TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

**Index** :
- `username` (UNIQUE)
- `email` (UNIQUE)

---

#### 🗂️ **Table: `diagnostics`**
```sql
CREATE TABLE diagnostics (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  maladie_type TEXT NOT NULL CHECK(maladie_type IN ('paludisme', 'typhoide', 'mixte')),
  image_path TEXT,
  image_base64 TEXT,
  resultat_ia JSON,
  confiance REAL,
  statut TEXT NOT NULL DEFAULT 'positif' CHECK(statut IN ('positif', 'negatif', 'incertain')),
  quantite_parasites REAL,
  commentaires TEXT,
  latitude REAL,
  longitude REAL,
  adresse TEXT,
  region TEXT,
  prefecture TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id)
);
```

**Index** :
- `idx_diagnostics_user` (user_id)
- `idx_diagnostics_date` (created_at)
- `idx_diagnostics_location` (latitude, longitude)
- `idx_diagnostics_maladie` (maladie_type)

---

#### 🗂️ **Table: `epidemics`**
```sql
CREATE TABLE epidemics (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  region TEXT NOT NULL,
  prefecture TEXT,
  maladie_type TEXT NOT NULL,
  nombre_cas INTEGER NOT NULL,
  date_debut DATE NOT NULL,
  date_fin DATE,
  statut TEXT NOT NULL DEFAULT 'actif' CHECK(statut IN ('actif', 'resolu', 'surveille')),
  niveau_alerte TEXT CHECK(niveau_alerte IN ('vert', 'jaune', 'orange', 'rouge')),
  actions_prises TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

**Index** :
- `idx_epidemics_region` (region)

---

#### 🗂️ **Table: `samples`**
```sql
CREATE TABLE samples (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  diagnostic_id INTEGER NOT NULL,
  barcode TEXT UNIQUE,
  sample_type TEXT,
  collection_date DATETIME,
  lab_id INTEGER,
  lab_result TEXT,
  lab_result_date DATETIME,
  status TEXT DEFAULT 'pending' CHECK(status IN ('pending', 'sent', 'received', 'processed', 'completed')),
  metadata JSON,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (diagnostic_id) REFERENCES diagnostics(id)
);
```

**Index** :
- `idx_samples_diagnostic` (diagnostic_id)
- `idx_samples_barcode` (barcode)

---

#### 🗂️ **Table: `health_centers`**
```sql
CREATE TABLE health_centers (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  type TEXT,
  latitude REAL,
  longitude REAL,
  address TEXT,
  region TEXT,
  prefecture TEXT,
  phone TEXT,
  email TEXT,
  resources JSON,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

---

#### 🗂️ **Table: `permissions`**
```sql
CREATE TABLE permissions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  role TEXT NOT NULL,
  resource TEXT NOT NULL,
  action TEXT NOT NULL,
  allowed BOOLEAN DEFAULT 1,
  UNIQUE(role, resource, action)
);
```

**Exemples de permissions** :
- `agent` → `diagnostics:create`, `diagnostics:read_own`
- `supervisor` → `diagnostics:read_all`, `diagnostics:update`
- `epidemiologist` → `dashboard:read`, `reports:create`
- `admin` → `*:*` (tous accès)

---

#### 🗂️ **Table: `audit_log`**
```sql
CREATE TABLE audit_log (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER,
  action TEXT NOT NULL,
  resource TEXT,
  resource_id INTEGER,
  details JSON,
  ip_address TEXT,
  user_agent TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id)
);
```

**Index** :
- `idx_audit_user` (user_id)
- `idx_audit_date` (created_at)

---

#### 🗂️ **Table: `notifications`**
```sql
CREATE TABLE notifications (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER,
  type TEXT NOT NULL,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  resource_type TEXT,
  resource_id INTEGER,
  read BOOLEAN DEFAULT 0,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id)
);
```

**Index** :
- `idx_notifications_user` (user_id, read)

---

#### 🗂️ **Table: `chatbot_conversations`**
```sql
CREATE TABLE chatbot_conversations (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  title TEXT NOT NULL,
  closed_at DATETIME,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id)
);
```

---

#### 🗂️ **Table: `chatbot_messages`**
```sql
CREATE TABLE chatbot_messages (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  conversation_id INTEGER NOT NULL,
  role TEXT NOT NULL CHECK(role IN ('user', 'assistant')),
  message TEXT NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (conversation_id) REFERENCES chatbot_conversations(id)
);
```

**Index** :
- `idx_chatbot_conversations_user` (user_id, closed_at)
- `idx_chatbot_messages_conversation` (conversation_id, created_at)

---

#### 🗂️ **Tables Supplémentaires**

| Table | Description | Clés Étrangères |
|-------|-------------|-----------------|
| `comments` | Commentaires sur diagnostics | `diagnostic_id`, `user_id` |
| `attachments` | Pièces jointes multiples | `diagnostic_id` |
| `geofences` | Zones d'alerte géographique | - |
| `campaigns` | Campagnes de santé publique | `created_by` |
| `reports` | Rapports générés | `generated_by` |
| `appointments` | Rendez-vous patients | `diagnostic_id`, `created_by` |
| `treatment_followup` | Suivi traitement | `diagnostic_id`, `appointment_id` |
| `ml_model_versions` | Versions modèles ML | - |
| `ml_feedback` | Feedback pour amélioration IA | `diagnostic_id`, `user_id` |
| `offline_queue` | File d'attente offline | `user_id` |
| `refresh_tokens` | Tokens de rafraîchissement JWT | `user_id` |
| `totp_secrets` | Secrets 2FA TOTP | `user_id` |
| `patient_history` | Historique patient | `diagnostic_id` |
| `tasks` | Tâches et workflow | `assigned_to`, `created_by` |
| `chat_messages` | Messages chat contextuel | `diagnostic_id`, `user_id` |
| `daily_stats` | Statistiques journalières | - |

---

## 🛠️ Technologies

### Backend

| Technologie | Version | Usage |
|------------|---------|-------|
| **Node.js** | 20+ | Runtime JavaScript |
| **Express** | 4.x | Framework web |
| **SQLite** | 3.x | Base de données |
| **Socket.IO** | 4.x | WebSocket temps réel |
| **JWT** | 9.x | Authentification |
| **bcrypt** | 5.x | Hashage mots de passe |
| **Multer** | 1.x | Upload fichiers |
| **Joi** | 17.x | Validation données |
| **Helmet** | 7.x | Sécurité HTTP headers |
| **Morgan** | 1.x | Logging HTTP |
| **express-rate-limit** | 7.x | Rate limiting |
| **@google/generative-ai** | - | Gemini AI chatbot |
| **BullMQ** | - | Job queue |
| **Sharp** | - | Traitement images |

### Frontend

| Technologie | Version | Usage |
|------------|---------|-------|
| **Flutter** | 3.7+ | Framework UI |
| **Dart** | 3.7+ | Langage de programmation |
| **Provider** | 6.x | State management |
| **http** | 1.x | Client HTTP |
| **socket_io_client** | 2.x | WebSocket client |
| **shared_preferences** | 2.x | Stockage local |
| **sqflite** | 2.x | Base de données locale |
| **image_picker** | 1.x | Sélection images |
| **camera** | 0.11+ | Caméra |
| **geolocator** | 11.x | Géolocalisation |
| **image** | 4.x | Traitement images |
| **mobile_scanner** | 7.x | Scanner code-barres |
| **flutter_localizations** | - | Internationalisation |

---

## 📦 Installation

### Prérequis

- **Node.js** >= 20.x
- **npm** >= 9.x
- **Flutter** >= 3.7.x
- **Dart** >= 3.7.x
- **Git**

### Installation Backend

```bash
# Cloner le repository
git clone https://github.com/votre-repo/HEALTHER.git
cd HEALTHER/backend

# Installer les dépendances
npm install

# Configurer l'environnement
cp env.example .env
# Éditer .env avec vos configurations

# Initialiser la base de données
npm run init-db

# Créer un utilisateur de test (optionnel)
node scripts/create-user.js
```

### Installation Frontend

```bash
cd ../healther

# Installer les dépendances Flutter
flutter pub get

# Pour iOS (sur macOS uniquement)
cd ios && pod install && cd ..

# Vérifier la configuration
flutter doctor
```

---

## ⚙️ Configuration

### Fichier `.env` Backend

```env
# Server
PORT=3000
NODE_ENV=development

# Database
DB_PATH=./data/made.db

# JWT
JWT_SECRET=your-super-secret-jwt-key-change-in-production
JWT_ACCESS_EXPIRY=15m
JWT_REFRESH_EXPIRY=30d

# CORS
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080

# Gemini AI Chatbot
GEMINI_API_KEY=your-gemini-api-key-here
GEMINI_MODEL=models/gemini-2.5-flash

# Storage (S3/MinIO ou local)
STORAGE_PROVIDER=local
S3_BUCKET=healther-diagnostics
S3_ACCESS_KEY=your-s3-access-key
S3_SECRET_KEY=your-s3-secret-key
S3_REGION=us-east-1
S3_ENDPOINT=

# SMS (Twilio/AWS SNS)
SMS_PROVIDER=twilio
TWILIO_ACCOUNT_SID=your-twilio-sid
TWILIO_AUTH_TOKEN=your-twilio-token
TWILIO_PHONE_NUMBER=+1234567890

# WhatsApp Business API
WHATSAPP_API_URL=https://api.whatsapp.com/v1
WHATSAPP_API_KEY=your-whatsapp-api-key

# Firebase Cloud Messaging (FCM)
FCM_SERVER_KEY=your-fcm-server-key

# USSD Gateway
USSD_API_KEY=your-ussd-api-key
USSD_API_URL=https://api.ussd-gateway.com/send

# Redis (pour BullMQ)
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=

# Monitoring (Prometheus)
PROMETHEUS_ENABLED=true
```

### Configuration Flutter

Dans `healther/lib/main.dart`, définir l'URL de l'API :

```dart
const String API_BASE_URL = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:3000',
);
```

Ou via ligne de commande :

```bash
flutter run -d linux --dart-define=API_BASE_URL=http://localhost:3000
```

---

## 🚀 Démarrage

### Démarrer le Backend

```bash
cd backend

# Mode développement (avec nodemon)
npm run dev

# Mode production
npm start

# Le serveur sera disponible sur http://localhost:3000
```

### Démarrer le Frontend

```bash
cd healther

# Mode développement
flutter run -d linux

# Avec configuration personnalisée
flutter run -d linux --dart-define=API_BASE_URL=http://votre-api:3000
```

### Vérification

- ✅ Backend : http://localhost:3000/health
- ✅ Swagger UI : http://localhost:3000/api-docs
- ✅ Flutter : L'application démarre automatiquement

---

## 📱 Utilisation

### Première Connexion

1. **Lancer l'application Flutter**
2. **S'identifier** :
   - Username : `agent1`
   - Password : `Agent123!`
3. **Autoriser les permissions** : Caméra, Localisation, Stockage

### Créer un Diagnostic

1. Ouvrir l'application
2. Cliquer sur **"Nouveau Diagnostic"**
3. Choisir le type de maladie (Paludisme/Typhoïde)
4. **Capturer ou sélectionner** une image
5. Attendre l'**analyse ML automatique**
6. Vérifier les **résultats** (confiance, statut)
7. Ajouter des **commentaires** (optionnel)
8. Valider → Le diagnostic est sauvegardé et géolocalisé

### Consulter le Dashboard

1. Ouvrir le **menu** (icône hamburger)
2. Sélectionner **"Tableau de Bord"**
3. Visualiser les **statistiques** :
   - Nombre de cas (positifs/négatifs)
   - Taux de positivité
   - Répartition par région
   - Courbes temporelles

### Utiliser le Chatbot IA

1. Ouvrir le **menu**
2. Cliquer sur **"Chatbot IA"**
3. Poser des questions, exemples :
   - "Quels sont les symptômes du paludisme ?"
   - "Comment utiliser cette application ?"
   - "Quelle est la différence entre paludisme et typhoïde ?"

---

## 🔐 Sécurité

### Authentification

- ✅ **JWT** avec access/refresh tokens
- ✅ **Bcrypt** pour le hashage des mots de passe
- ✅ **2FA (TOTP)** optionnel pour les comptes sensibles
- ✅ **Rate limiting** sur les endpoints critiques (100 req/min)
- ✅ **Helmet** pour sécuriser les headers HTTP

### Autorisation

- ✅ **RBAC** (Role-Based Access Control) avec permissions granulaires
- ✅ **Middleware** `authenticateToken` et `checkPermission` sur toutes les routes
- ✅ **Audit log** pour traçabilité complète des actions

### Protection des Données

- ✅ **CORS** configuré avec whitelist d'origines
- ✅ **Validation** des données avec Joi
- ✅ **Sanitization** des uploads (taille, type MIME)
- ✅ **HTTPS** recommandé en production
- ✅ **Tokens** avec expiration courte (15 min access, 30 jours refresh)

### Sécurité des Fichiers

- ✅ **Limite de taille** : 10MB par fichier
- ✅ **Whitelist MIME types** : image/jpeg, image/png
- ✅ **Noms de fichiers sécurisés** (pas de path traversal)
- ✅ **Stockage isolé** (S3/MinIO ou dossier sécurisé)

---

## 🤖 IA et ML

### Analyse d'Images

Le système utilise plusieurs approches pour l'analyse d'images :

1. **TensorFlow.js** (local) : Analyse basique sur l'appareil
2. **Google Vision API** : Détection avancée (configurer `GOOGLE_VISION_API_KEY`)
3. **AWS Rekognition** : Alternative cloud (configurer AWS credentials)

### Chatbot Gemini

Le chatbot utilise **Google Gemini AI** (`models/gemini-2.5-flash`) pour :
- Répondre aux questions médicales
- Guider les agents dans l'utilisation de l'application
- Fournir des informations contextuelles selon le rôle et la région

**Configuration** :
```env
GEMINI_API_KEY=your-api-key
GEMINI_MODEL=models/gemini-2.5-flash
```

### Amélioration Continue

- **Feedback ML** : Les utilisateurs peuvent corriger les prédictions IA
- **Versions de modèles** : Traçabilité des versions et métriques
- **A/B Testing** : Comparaison de modèles pour optimisation

---

## 📊 API Documentation

### Endpoints Principaux

#### Authentification

| Méthode | Endpoint | Description | Auth |
|---------|----------|-------------|------|
| `POST` | `/api/users/register` | Inscription | ❌ |
| `POST` | `/api/users/login` | Connexion | ❌ |
| `POST` | `/api/users/refresh` | Rafraîchir token | ❌ |
| `POST` | `/api/users/logout` | Déconnexion | ✅ |
| `GET` | `/api/users` | Liste utilisateurs | ✅ |
| `GET` | `/api/users/:id` | Détails utilisateur | ✅ |
| `PUT` | `/api/users/:id/profile-picture` | Upload photo profil | ✅ |
| `DELETE` | `/api/users/:id/profile-picture` | Supprimer photo | ✅ |

#### Diagnostics

| Méthode | Endpoint | Description | Auth |
|---------|----------|-------------|------|
| `GET` | `/api/diagnostics` | Liste diagnostics | ✅ |
| `GET` | `/api/diagnostics/:id` | Détails diagnostic | ✅ |
| `POST` | `/api/diagnostics` | Créer diagnostic | ✅ |
| `PUT` | `/api/diagnostics/:id` | Modifier diagnostic | ✅ |
| `DELETE` | `/api/diagnostics/:id` | Supprimer diagnostic | ✅ |

#### Chatbot IA

| Méthode | Endpoint | Description | Auth |
|---------|----------|-------------|------|
| `GET` | `/api/chatbot/conversation` | Récupérer/créer conversation | ✅ |
| `POST` | `/api/chatbot/message` | Envoyer message | ✅ |
| `GET` | `/api/chatbot/conversations` | Liste conversations | ✅ |
| `POST` | `/api/chatbot/conversation/:id/close` | Fermer conversation | ✅ |

#### Dashboard

| Méthode | Endpoint | Description | Auth |
|---------|----------|-------------|------|
| `GET` | `/api/dashboard/stats` | Statistiques globales | ✅ |
| `GET` | `/api/dashboard/trends` | Tendances temporelles | ✅ |
| `GET` | `/api/dashboard/heatmap` | Heatmap géographique | ✅ |

### Exemple de Requête

```bash
# Connexion
curl -X POST http://localhost:3000/api/users/login \
  -H "Content-Type: application/json" \
  -d '{"username":"agent1","password":"Agent123!"}'

# Réponse
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "abc123...",
  "user": { ... }
}

# Créer un diagnostic (avec token)
curl -X POST http://localhost:3000/api/diagnostics \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "maladie_type": "paludisme",
    "image_base64": "base64encodedimage...",
    "latitude": 6.1375,
    "longitude": 1.2123,
    "region": "Lomé"
  }'
```

### Documentation Swagger

Accéder à la documentation interactive :
```
http://localhost:3000/api-docs
```

---

## 🧪 Tests

### Tests Backend

```bash
cd backend

# Tests unitaires (à implémenter)
npm test

# Tests d'intégration
npm run test:integration
```

### Tests Frontend

```bash
cd healther

# Tests unitaires
flutter test

# Tests d'intégration
flutter test integration_test/
```

---

## 📈 Roadmap

### ✅ Phase 1 - Complétée

- [x] Architecture backend/frontend
- [x] Authentification JWT avec refresh tokens
- [x] CRUD diagnostics avec analyse ML
- [x] Géolocalisation et tracking
- [x] Système de permissions RBAC
- [x] Dashboard avec statistiques
- [x] Notifications temps réel (WebSocket)
- [x] Chatbot IA Gemini
- [x] Upload photos de profil
- [x] Fonctionnement offline avec sync

### 🚀 Phase 2 - En cours

- [ ] Export rapports PDF/Excel
- [ ] Intégration SMS/USSD
- [ ] Intégration WhatsApp Business
- [ ] FHIR/HL7 pour échange de données
- [ ] Application web admin console
- [ ] Monitoring Prometheus/Grafana
- [ ] Tests automatisés complets
- [ ] Documentation API complète

### 🔮 Phase 3 - À venir

- [ ] Application mobile native (Android/iOS)
- [ ] Mode sombre
- [ ] Multilingue complet (FR/EN/local)
- [ ] Vidéos tutoriels intégrés
- [ ] Analyse prédictive avancée
- [ ] Intégration blockchain pour traçabilité
- [ ] API publique pour partenaires

---

## 🤝 Contribution

Les contributions sont les bienvenues ! Merci de suivre ces étapes :

1. **Fork** le projet
2. Créer une **branche** (`git checkout -b feature/AmazingFeature`)
3. **Commit** vos changements (`git commit -m 'Add some AmazingFeature'`)
4. **Push** vers la branche (`git push origin feature/AmazingFeature`)
5. Ouvrir une **Pull Request**

### Standards de Code

- **Backend** : ESLint + Prettier
- **Frontend** : `flutter analyze` + `flutter format`
- **Commits** : Conventionnel (feat:, fix:, docs:, etc.)

---

## 📄 License

Ce projet est sous licence **MIT**. Voir le fichier `LICENSE` pour plus de détails.

---

## 📞 Contact & Support

- **Email** : support@healther.app
- **Documentation** : https://docs.healther.app
- **Issues** : https://github.com/votre-repo/HEALTHER/issues

---

<p align="center">
  <strong>Fait avec ❤️ pour améliorer la santé publique</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/github/stars/votre-repo/HEALTHER?style=social" alt="GitHub stars">
  <img src="https://img.shields.io/github/forks/votre-repo/HEALTHER?style=social" alt="GitHub forks">
  <img src="https://img.shields.io/github/watchers/votre-repo/HEALTHER?style=social" alt="GitHub watchers">
</p>

---

## 📚 Ressources Additionnelles

- [Guide d'Architecture](./ARCHITECTURE.md)
- [Guide de Démarrage](./DEMARRAGE.md)
- [Guide de Production](./PRODUCTION.md)
- [Documentation ML](./INTEGRATION_ML.md)

---

*Dernière mise à jour : Novembre 2024*
# HEALTHER
