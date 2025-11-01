# 🔑 Configuration des Clés API - HEALTHER

Ce document liste toutes les clés API nécessaires pour le bon fonctionnement de l'application HEALTHER.

## ⚠️ Important

**Pour le développement local, aucune clé API n'est strictement nécessaire** - l'application fonctionnera avec des placeholders et des fonctionnalités de base.

Cependant, pour utiliser les fonctionnalités avancées (ML, notifications externes, etc.), vous devrez configurer les clés API suivantes dans le fichier `.env` du backend.

---

## 📋 Clés API Nécessaires

### 1. 🔍 **Machine Learning / Analyse d'Images**

Ces clés permettent d'utiliser des services cloud pour l'analyse d'images médicales :

#### Google Vision API (Optionnel)
```env
GOOGLE_VISION_API_KEY=your-google-vision-api-key-here
```
- **Où obtenir** : [Google Cloud Console](https://console.cloud.google.com/)
- **Usage** : Analyse d'images avec Google Vision API
- **Obligatoire** : ❌ Non (l'application utilise Sharp par défaut)

#### AWS Rekognition (Optionnel)
```env
AWS_ACCESS_KEY_ID=your-aws-access-key-id
AWS_SECRET_ACCESS_KEY=your-aws-secret-access-key
AWS_REGION=us-east-1
```
- **Où obtenir** : [AWS Console](https://console.aws.amazon.com/)
- **Usage** : Analyse d'images avec AWS Rekognition
- **Obligatoire** : ❌ Non (alternative à Google Vision)

#### TensorFlow Model (Optionnel)
```env
MODEL_PATH=/path/to/tflite/model.tflite
ML_ANALYSIS_PROVIDER=sharp  # Options: 'sharp', 'google', 'aws', 'tensorflow'
```
- **Où obtenir** : Modèle personnalisé TensorFlow Lite
- **Usage** : Analyse d'images avec modèle ML local
- **Obligatoire** : ❌ Non

---

### 2. 📱 **Notifications Externes**

Ces clés permettent d'envoyer des notifications par SMS, WhatsApp, Push, etc.

#### SMS Provider (Optionnel)
```env
SMS_API_KEY=your-sms-api-key-here
SMS_API_URL=https://api.sms-provider.com/send
```
- **Où obtenir** : Twilio, AWS SNS, ou autre fournisseur SMS
- **Usage** : Envoyer des SMS aux utilisateurs
- **Obligatoire** : ❌ Non (simulation en mode dev)

#### WhatsApp Business API (Optionnel)
```env
WHATSAPP_API_KEY=your-whatsapp-api-key-here
WHATSAPP_API_URL=https://graph.facebook.com/v18.0/your-phone-number-id/messages
```
- **Où obtenir** : [Meta for Developers](https://developers.facebook.com/docs/whatsapp)
- **Usage** : Envoyer des messages WhatsApp
- **Obligatoire** : ❌ Non

#### Firebase Cloud Messaging (Push Notifications) (Optionnel)
```env
FCM_SERVER_KEY=your-fcm-server-key-here
```
- **Où obtenir** : [Firebase Console](https://console.firebase.google.com/)
- **Usage** : Notifications push sur mobile
- **Obligatoire** : ❌ Non (WebSocket utilisé par défaut)

#### USSD Gateway (Optionnel)
```env
USSD_API_KEY=your-ussd-api-key-here
USSD_API_URL=https://api.ussd-provider.com/send
```
- **Où obtenir** : Fournisseur USSD local
- **Usage** : Interaction via USSD (pays en développement)
- **Obligatoire** : ❌ Non

---

### 3. 🗺️ **Géolocalisation**

**Aucune clé API requise !** ✅

L'application utilise :
- `geolocator` (Flutter) - Pas de clé API nécessaire
- `geocoding` (Flutter) - Utilise les services système
- Les permissions sont déjà configurées dans `AndroidManifest.xml`

---

## 🚀 Fonctionnement Sans Clés API

### Mode Par Défaut (Développement)

1. **Géolocalisation** ✅ Fonctionne automatiquement avec les permissions
2. **Notifications** ✅ Fonctionne via WebSocket (in-app) sans clé API
3. **Analyse ML** ✅ Utilise Sharp (preprocessing) + analyse basique
4. **Stockage Offline** ✅ Fonctionne avec SQLite local

### Limitations Sans Clés API

- ❌ Pas d'envoi de SMS/WhatsApp/Push externes
- ❌ Pas d'analyse ML cloud (Google Vision, AWS Rekognition)
- ✅ Toutes les autres fonctionnalités fonctionnent normalement

---

## 📝 Configuration Backend

Créez un fichier `.env` dans le dossier `backend/` :

```bash
cd backend
cp .env.example .env  # Si le fichier existe
# Ou créez-le manuellement
```

Ajoutez vos clés API (exemple minimal) :

```env
# Configuration Backend
PORT=3000
NODE_ENV=development

# Base de données (SQLite par défaut)
DB_PATH=./healther.db

# JWT
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
JWT_REFRESH_SECRET=your-super-secret-refresh-key-change-this-in-production

# Clés API (Optionnelles - uniquement pour fonctionnalités avancées)
GOOGLE_VISION_API_KEY=
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
SMS_API_KEY=
WHATSAPP_API_KEY=
FCM_SERVER_KEY=
```

---

## ✅ Checklist d'Intégration

### Services Intégrés dans l'App

- ✅ **LocationService** - Intégré dans `DiagnosticProvider`
- ✅ **OfflineQueueService** - Intégré dans `DiagnosticProvider`
- ✅ **NotificationService** - Intégré via `NotificationProvider` (main.dart)
- ✅ **GeofencingService** - Utilisé dans `MapHeatmapScreen`
- ✅ **CameraService** - Utilisé dans les écrans de diagnostic
- ✅ **BarcodeScannerService** - Utilisé dans `BarcodeScannerScreen`
- ✅ **LocalizationService** - Intégré dans `main.dart`
- ✅ **AccessibilityService** - Intégré dans `main.dart`

### Providers Intégrés dans main.dart

- ✅ `AuthProvider` - Authentification
- ✅ `DiagnosticProvider` - Diagnostics
- ✅ `NotificationProvider` - Notifications (✅ **Ajouté**)
- ✅ `MLFeedbackProvider` - Feedback ML (✅ **Ajouté**)

### Endpoints dans ApiService

- ✅ Utilisateurs (login, register, getUser, uploadProfilePicture)
- ✅ Diagnostics (create, get, upload)
- ✅ Dashboard (stats, epidemics, mapData)
- ✅ ML Feedback
- ✅ Samples
- ✅ Comments
- ✅ Appointments
- ✅ Reports
- ✅ Campaigns
- ✅ Health Centers
- ✅ Tasks (✅ **Ajouté**)
- ✅ Notifications (✅ **Ajouté**)
- ✅ Geofencing (✅ **Ajouté**)
- ✅ Offline Queue (✅ **Ajouté**)

---

## 🔒 Sécurité

⚠️ **IMPORTANT** : Ne commitez JAMAIS le fichier `.env` avec vos vraies clés API !

Assurez-vous que `.env` est dans `.gitignore` :

```gitignore
# Backend
backend/.env

# Autres fichiers sensibles
*.env
.env.local
```

---

## 📚 Ressources

- [Google Cloud Console](https://console.cloud.google.com/)
- [AWS Console](https://console.aws.amazon.com/)
- [Firebase Console](https://console.firebase.google.com/)
- [Meta for Developers](https://developers.facebook.com/)
- [Twilio Documentation](https://www.twilio.com/docs)

---

## ❓ Questions Fréquentes

**Q: Dois-je configurer toutes les clés API ?**  
R: Non, seules les fonctionnalités que vous souhaitez utiliser nécessitent leurs clés API respectives.

**Q: L'application fonctionne-t-elle sans clés API ?**  
R: Oui, toutes les fonctionnalités de base fonctionnent. Seules les fonctionnalités avancées (notifications externes, ML cloud) nécessitent des clés API.

**Q: La géolocalisation nécessite-t-elle une clé API ?**  
R: Non, la géolocalisation utilise les services système (GPS) et fonctionne automatiquement avec les permissions configurées.

