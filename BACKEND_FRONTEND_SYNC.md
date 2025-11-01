# 🔄 Synchronisation Backend-Frontend - HEALTHER

Ce document vérifie que tous les endpoints ajoutés dans `ApiService` correspondent bien aux routes du backend.

---

## ✅ ENDPOINTS SYNCHRONISÉS

### 📱 **Notifications**

| Endpoint Frontend (ApiService) | Route Backend | Méthode | Statut |
|--------------------------------|---------------|---------|--------|
| `getNotifications()` | `/api/notifications` | GET | ✅ Sync |
| `markNotificationAsRead(id)` | `/api/notifications/:id/read` | PUT | ✅ Sync |
| `markAllNotificationsAsRead()` | `/api/notifications/read-all` | PUT | ✅ Sync |
| `getUnreadNotificationCount()` | `/api/notifications/unread-count` | GET | ✅ Sync |

**Fichier Backend** : `backend/routes/notifications.js` ✅

---

### 🗺️ **Geofencing**

| Endpoint Frontend (ApiService) | Route Backend | Méthode | Statut |
|--------------------------------|---------------|---------|--------|
| `getActiveGeofences()` | `/api/geofencing` | GET | ✅ Sync |
| `checkGeofencingAlerts()` | `/api/geofencing/check-alerts` | GET | ✅ Sync |
| `getGeofencingHeatmap()` | `/api/geofencing/heatmap` | GET | ✅ Sync |

**Fichier Backend** : `backend/routes/geofencing.js` ✅

**Note** : Le backend a également une route POST pour créer des géofences (`POST /api/geofencing`) qui pourrait être ajoutée dans ApiService si nécessaire.

---

### 📦 **Offline Queue**

| Endpoint Frontend (ApiService) | Route Backend | Méthode | Statut |
|--------------------------------|---------------|---------|--------|
| `getOfflineQueueItems()` | `/api/offline-queue` | GET | ✅ Sync |
| `syncOfflineQueueItem(id)` | `/api/offline-queue/sync/:id` | POST | ✅ Sync |
| `deleteOfflineQueueItem(id)` | `/api/offline-queue/:id` | DELETE | ✅ Sync |

**Fichier Backend** : `backend/routes/offline_queue.js` ✅

**Correction effectuée** : La méthode `syncOfflineQueue()` a été corrigée pour accepter un `itemId` et correspondre à la route backend `/sync/:id`.

---

### 📋 **Tasks**

| Endpoint Frontend (ApiService) | Route Backend | Méthode | Statut |
|--------------------------------|---------------|---------|--------|
| `createTask()` | `/api/tasks` | POST | ✅ Sync |
| `getTasks()` | `/api/tasks?status=...` | GET | ✅ Sync |
| `updateTaskStatus(id, status)` | `/api/tasks/:id/status` | PATCH | ✅ Sync |
| `getOverdueTasks()` | `/api/tasks/overdue` | GET | ✅ Sync |

**Fichier Backend** : `backend/routes/tasks.js` ✅

---

### 🔐 **Users**

| Endpoint Frontend (ApiService) | Route Backend | Méthode | Statut |
|--------------------------------|---------------|---------|--------|
| `login()` | `/api/users/login` | POST | ✅ Sync |
| `register()` | `/api/users/register` | POST | ✅ Sync |
| `getUser(id)` | `/api/users/:id` | GET | ✅ Sync |
| `uploadProfilePicture(id, file)` | `/api/users/:id/profile-picture` | PUT | ✅ Sync |
| `deleteProfilePicture(id)` | `/api/users/:id/profile-picture` | DELETE | ✅ Sync |

**Fichier Backend** : `backend/routes/users.js` ✅

---

### 🩺 **Diagnostics**

| Endpoint Frontend (ApiService) | Route Backend | Méthode | Statut |
|--------------------------------|---------------|---------|--------|
| `createDiagnostic()` | `/api/diagnostics` | POST | ✅ Sync |
| `createDiagnosticUpload()` | `/api/diagnostics/upload` | POST | ✅ Sync |
| `getDiagnostics()` | `/api/diagnostics?user_id=...` | GET | ✅ Sync |
| `getDiagnostic(id)` | `/api/diagnostics/:id` | GET | ✅ Sync |

**Fichier Backend** : `backend/routes/diagnostics.js` ✅

---

### 📊 **Dashboard**

| Endpoint Frontend (ApiService) | Route Backend | Méthode | Statut |
|--------------------------------|---------------|---------|--------|
| `getStats()` | `/api/dashboard/stats` | GET | ✅ Sync |
| `getEpidemics()` | `/api/dashboard/epidemics` | GET | ✅ Sync |
| `getMapData()` | `/api/dashboard/map` | GET | ✅ Sync |

**Fichier Backend** : `backend/routes/dashboard.js` ✅

---

### 🤖 **ML Feedback**

| Endpoint Frontend (ApiService) | Route Backend | Méthode | Statut |
|--------------------------------|---------------|---------|--------|
| `submitMLFeedback()` | `/api/ml-feedback` | POST | ✅ Sync |

**Fichier Backend** : `backend/routes/ml_feedback.js` ✅

---

### 🧪 **Samples**

| Endpoint Frontend (ApiService) | Route Backend | Méthode | Statut |
|--------------------------------|---------------|---------|--------|
| `createSample()` | `/api/samples` | POST | ✅ Sync |
| `getSampleByBarcode(barcode)` | `/api/samples/barcode/:barcode` | GET | ✅ Sync |

**Fichier Backend** : `backend/routes/samples.js` ✅

---

### 💬 **Comments**

| Endpoint Frontend (ApiService) | Route Backend | Méthode | Statut |
|--------------------------------|---------------|---------|--------|
| `createComment()` | `/api/comments` | POST | ✅ Sync |
| `getDiagnosticComments(id)` | `/api/comments/diagnostic/:id` | GET | ✅ Sync |

**Fichier Backend** : `backend/routes/comments.js` ✅

---

### 📅 **Appointments**

| Endpoint Frontend (ApiService) | Route Backend | Méthode | Statut |
|--------------------------------|---------------|---------|--------|
| `createAppointment()` | `/api/appointments` | POST | ✅ Sync |

**Fichier Backend** : `backend/routes/appointments.js` ✅

---

### 📄 **Reports**

| Endpoint Frontend (ApiService) | Route Backend | Méthode | Statut |
|--------------------------------|---------------|---------|--------|
| `generateReport()` | `/api/reports/generate` | POST | ✅ Sync |

**Fichier Backend** : `backend/routes/reports.js` ✅

---

### 🎯 **Campaigns**

| Endpoint Frontend (ApiService) | Route Backend | Méthode | Statut |
|--------------------------------|---------------|---------|--------|
| `createCampaign()` | `/api/campaigns` | POST | ✅ Sync |
| `getCampaigns()` | `/api/campaigns?status=...` | GET | ✅ Sync |

**Fichier Backend** : `backend/routes/campaigns.js` ✅

---

### 🏥 **Health Centers**

| Endpoint Frontend (ApiService) | Route Backend | Méthode | Statut |
|--------------------------------|---------------|---------|--------|
| `getHealthCenters()` | `/api/health-centers?region=...` | GET | ✅ Sync |

**Fichier Backend** : `backend/routes/health_centers.js` ✅

---

## ⚠️ **ENDPOINTS BACKEND NON UTILISÉS DANS FRONTEND**

### Routes backend disponibles mais non utilisées dans ApiService :

1. **Geofencing** :
   - `POST /api/geofencing` - Créer une zone géofencing (nécessite permission `geofences:create`)

2. **Offline Queue** :
   - `DELETE /api/offline-queue/:id` - Supprimer un item synchronisé ✅ **Maintenant ajouté**

3. **Tasks** :
   - Toutes les routes sont utilisées ✅

4. **Autres routes backend non utilisées** :
   - `/api/chat` - Chat
   - `/api/chatbot` - Chatbot
   - `/api/search` - Recherche
   - `/api/patient-history` - Historique patient
   - `/api/totp` - Authentification TOTP
   - `/api/monitoring` - Monitoring
   - `/api/fhir` - FHIR

**Note** : Ces routes peuvent être ajoutées dans ApiService si nécessaire.

---

## ✅ **RÉSUMÉ**

- **Endpoints synchronisés** : 35+ endpoints ✅
- **Endpoints backend disponibles mais non utilisés** : ~10 (optionnels)
- **Statut global** : **100% des endpoints utilisés dans le frontend sont synchronisés avec le backend** ✅

---

## 📝 **CORRECTIONS EFFECTUÉES**

1. ✅ **Offline Queue** : Correction de `syncOfflineQueue()` → `syncOfflineQueueItem(id)` pour correspondre à `/sync/:id`
2. ✅ **Offline Queue** : Ajout de `deleteOfflineQueueItem(id)` pour correspondre à `DELETE /:id`

---

## 🔄 **MAINTENANCE**

Pour maintenir la synchronisation :

1. **Lors de l'ajout d'une nouvelle route backend** :
   - Vérifier si elle doit être utilisée dans le frontend
   - Ajouter la méthode correspondante dans `ApiService`
   - Mettre à jour ce document

2. **Lors de l'ajout d'une nouvelle fonctionnalité frontend** :
   - Vérifier que la route backend existe
   - Si elle n'existe pas, créer la route backend d'abord
   - Ajouter la méthode dans `ApiService`
   - Mettre à jour ce document

---

**Dernière mise à jour** : Aujourd'hui  
**Statut** : ✅ Tous les endpoints sont synchronisés

