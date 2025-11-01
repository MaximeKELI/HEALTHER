# 🔑 API Keys Requises - HEALTHER

Liste de toutes les API keys nécessaires pour les fonctionnalités implémentées.

---

## ✅ **API KEYS CONFIGURÉES**

### 1. 🤖 **Google Gemini AI** ✅
**Clé API** : `AIzaSyDTTD9CZG7YZv8qhZlBMp3ok4qrDtmSKCE`
**Utilisation** : Assistant vocal IA avec Gemini
**Fichier** : `backend/services/gemini_voice_service.js` (ligne 11)
**Variable d'environnement** : `GEMINI_API_KEY`

**Endpoints utilisés** :
- Transcription audio → texte
- Chat conversationnel
- Génération de réponses audio

---

## 🔧 **API KEYS OPTIONNELLES (NON CONFIGURÉES)**

### 2. 📸 **Google ML Kit (OCR)** ⚠️
**Nécessite** : Aucune clé API (fonctionne hors ligne)
**Utilisation** : Scan et reconnaissance de prescriptions
**Package** : `google_ml_kit: ^0.18.0`
**Fichier** : `lib/services/ocr_service.dart`

**Note** : Google ML Kit fonctionne hors ligne, pas besoin d'API key.

---

### 3. 🌐 **Google Translate API** (Optionnel)
**Nécessite** : Clé API Google Cloud Translate
**Utilisation** : Traduction multilingue vocale
**Variable d'environnement** : `GOOGLE_TRANSLATE_API_KEY`
**Endpoint** : `https://translation.googleapis.com/language/translate/v2`

**Pour obtenir une clé** :
1. Aller sur [Google Cloud Console](https://console.cloud.google.com/)
2. Activer l'API "Cloud Translation API"
3. Créer une clé API
4. Ajouter dans `.env` : `GOOGLE_TRANSLATE_API_KEY=votre_cle_api`

**Fichier** : `lib/services/translation_service.dart` (actuellement placeholder)

---

### 4. 🔔 **Firebase Cloud Messaging (FCM)** (Optionnel)
**Nécessite** : Fichier `google-services.json` (Android) / `GoogleService-Info.plist` (iOS)
**Utilisation** : Notifications push
**Package** : `firebase_core`, `firebase_messaging`
**Configuration** : Nécessite projet Firebase configuré

**Pour configurer** :
1. Créer un projet sur [Firebase Console](https://console.firebase.google.com/)
2. Ajouter votre application Android/iOS
3. Télécharger les fichiers de configuration
4. Placer dans `android/app/` et `ios/Runner/`

**Fichier** : Non encore intégré (infrastructure prête)

---

### 5. 📧 **SMS/WhatsApp APIs** (Optionnel)
**Nécessite** : Clés API selon le provider (Twilio, Vonage, etc.)
**Utilisation** : Envoi de rappels et alertes par SMS/WhatsApp
**Variables d'environnement** :
- `SMS_API_KEY` / `SMS_API_URL`
- `WHATSAPP_API_KEY` / `WHATSAPP_API_URL`

**Pour Twilio** :
1. Créer un compte sur [Twilio](https://www.twilio.com/)
2. Obtenir `Account SID` et `Auth Token`
3. Ajouter dans `.env`

**Fichier** : `backend/services/notification_service.js` (placeholders)

---

### 6. 🔍 **Google Vision API** (Optionnel)
**Nécessite** : Clé API Google Cloud Vision
**Utilisation** : Analyse d'images médicales avancée
**Variable d'environnement** : `GOOGLE_VISION_API_KEY`
**Endpoint** : `https://vision.googleapis.com/v1/images:annotate`

**Pour obtenir** :
1. Google Cloud Console
2. Activer "Cloud Vision API"
3. Créer une clé API

**Fichier** : `backend/services/ml_service.js` (placeholders)

---

### 7. ☁️ **AWS Rekognition** (Optionnel)
**Nécessite** : AWS Access Key ID et Secret Access Key
**Utilisation** : Analyse d'images médicales alternative
**Variables d'environnement** :
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_REGION`

**Pour obtenir** :
1. Créer un compte AWS
2. Créer un utilisateur IAM avec accès Rekognition
3. Générer les clés d'accès

**Fichier** : `backend/services/ml_service.js` (placeholders)

---

## 📝 **CONFIGURATION DES VARIABLES D'ENVIRONNEMENT**

### Backend (`backend/.env`)

```env
# Gemini AI (CONFIGURÉ ✅)
GEMINI_API_KEY=AIzaSyDTTD9CZG7YZv8qhZlBMp3ok4qrDtmSKCE

# Google Translate (Optionnel)
GOOGLE_TRANSLATE_API_KEY=votre_cle_api_ici

# Google Vision API (Optionnel)
GOOGLE_VISION_API_KEY=votre_cle_api_ici

# AWS Rekognition (Optionnel)
AWS_ACCESS_KEY_ID=votre_access_key
AWS_SECRET_ACCESS_KEY=votre_secret_key
AWS_REGION=us-east-1

# SMS/WhatsApp (Optionnel)
SMS_API_KEY=votre_sms_api_key
SMS_API_URL=https://api.twilio.com/2010-04-01/Accounts/
WHATSAPP_API_KEY=votre_whatsapp_api_key
WHATSAPP_API_URL=https://graph.facebook.com/v18.0/

# Firebase (Optionnel - nécessite fichiers de config)
FCM_SERVER_KEY=votre_fcm_server_key
```

---

## ⚠️ **IMPORTANT : SÉCURITÉ**

1. **Ne jamais commit les clés API dans Git**
   - Ajouter `.env` dans `.gitignore`
   - Utiliser `.env.example` pour la documentation

2. **Pour la production** :
   - Utiliser des variables d'environnement du serveur
   - Ne jamais hardcoder les clés dans le code
   - Utiliser un gestionnaire de secrets (AWS Secrets Manager, HashiCorp Vault, etc.)

3. **Limiter les permissions** :
   - Créer des clés API avec permissions minimales nécessaires
   - Activer la rotation des clés régulièrement

---

## ✅ **STATUT ACTUEL**

| API | Statut | Action Requise |
|-----|--------|----------------|
| Gemini AI | ✅ Configuré | Aucune |
| Google ML Kit | ✅ Fonctionne | Aucune (hors ligne) |
| Google Translate | ⚠️ Placeholder | Ajouter clé API (optionnel) |
| Firebase FCM | ⚠️ Non configuré | Configurer projet Firebase (optionnel) |
| SMS/WhatsApp | ⚠️ Placeholder | Ajouter clés API (optionnel) |
| Google Vision | ⚠️ Placeholder | Ajouter clé API (optionnel) |
| AWS Rekognition | ⚠️ Placeholder | Ajouter clés AWS (optionnel) |

---

## 📚 **FONCTIONNALITÉS DISPONIBLES SANS API KEY**

Les fonctionnalités suivantes fonctionnent **sans API key externe** :

✅ **Authentification Biométrique** - Utilise les APIs natives du système
✅ **OCR Prescriptions** - Google ML Kit fonctionne hors ligne
✅ **Génération PDF/Excel** - Bibliothèques locales
✅ **Prédiction Épidémique** - Algorithme local basé sur données historiques
✅ **Dashboard Temps Réel** - WebSocket interne
✅ **Gamification** - Système local
✅ **Mode Offline** - SQLite local

---

**Note** : La plupart des fonctionnalités principales fonctionnent sans API keys externes. Les API keys sont optionnelles pour les fonctionnalités avancées.

