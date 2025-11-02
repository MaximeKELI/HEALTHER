# 🚀 Prochaines Étapes - Guide d'Intégration

Ce document décrit les étapes nécessaires pour intégrer et tester toutes les nouvelles fonctionnalités créées.

---

## ✅ Étape 1 : Installation des Dépendances Backend

```bash
cd backend
npm install
```

**Nouvelles dépendances installées** :
- `nodemailer` (v6.9.7) - Pour les emails SMTP

---

## ✅ Étape 2 : Initialisation de la Base de Données

```bash
cd backend
npm run init-db
```

**Nouvelles tables créées** :
- `medication_reminders` - Rappels de médicaments
- `medication_adherence` - Observance des médicaments

---

## ✅ Étape 3 : Configuration des Variables d'Environnement

Créer/copier le fichier `.env` dans `backend/` :

```env
# ... variables existantes ...

# ========== NOTIFICATIONS MULTICANAUX ==========

# Twilio (SMS et WhatsApp)
TWILIO_ACCOUNT_SID=votre_account_sid_twilio
TWILIO_AUTH_TOKEN=votre_auth_token_twilio
TWILIO_PHONE_NUMBER=+1234567890
TWILIO_WHATSAPP_NUMBER=whatsapp:+1234567890

# WhatsApp Business API (Meta) - Alternative
WHATSAPP_ACCESS_TOKEN=votre_access_token_meta
WHATSAPP_PHONE_NUMBER_ID=votre_phone_number_id
WHATSAPP_BUSINESS_ACCOUNT_ID=votre_business_account_id

# Email SMTP
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=votre_email@gmail.com
SMTP_PASSWORD=votre_mot_de_passe_app
SMTP_FROM=noreply@healther.com

# Firebase Cloud Messaging (Push)
FCM_SERVER_KEY=votre_fcm_server_key

# ========== MÉDICATIONS ==========

# OpenFDA et RxNorm sont GRATUITS, pas d'API key nécessaire
# DrugBank (optionnel)
DRUGBANK_API_KEY=votre_drugbank_key
```

### 📝 Comment obtenir les API Keys :

#### Twilio :
1. Créer un compte sur https://www.twilio.com/
2. Aller dans Console → Account → Account Info
3. Copier Account SID et Auth Token
4. Pour WhatsApp, activer Sandbox dans Messaging → Try it out

#### WhatsApp Business API (Meta) :
1. Créer une app sur https://developers.facebook.com/
2. Ajouter le produit "WhatsApp"
3. Générer Access Token
4. Obtenir Phone Number ID depuis WhatsApp Business API

#### SMTP Email :
1. Gmail : Créer un "App Password" dans Google Account
2. Autre fournisseur : Utiliser les credentials SMTP standards

#### Firebase FCM :
1. Aller dans Firebase Console → Project Settings → Cloud Messaging
2. Copier la Server Key

---

## ✅ Étape 4 : Démarrage du Serveur Backend

```bash
cd backend
npm start
# ou pour le développement avec hot-reload
npm run dev
```

**Vérification** :
- Serveur démarre sur http://localhost:3000
- Health check : http://localhost:3000/health
- API disponible : http://localhost:3000/api

---

## ✅ Étape 5 : Test des APIs

### Test Contact Tracing :

```bash
# Trouver les contacts d'un diagnostic
curl -X GET http://localhost:3000/api/contact-tracing/diagnostic/1/contacts \
  -H "Authorization: Bearer YOUR_TOKEN"

# Calculer R0
curl -X GET http://localhost:3000/api/contact-tracing/r0 \
  -H "Authorization: Bearer YOUR_TOKEN"

# Rapport d'investigation
curl -X GET http://localhost:3000/api/contact-tracing/diagnostic/1/investigation-report \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Test Notifications Multicanaux :

```bash
# Envoyer SMS
curl -X POST http://localhost:3000/api/notifications-multichannel/sms \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"to": "+1234567890", "message": "Test SMS"}'

# Envoyer WhatsApp
curl -X POST http://localhost:3000/api/notifications-multichannel/whatsapp \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"to": "+1234567890", "message": "Test WhatsApp"}'

# Envoyer Email
curl -X POST http://localhost:3000/api/notifications-multichannel/email \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"to": "test@example.com", "subject": "Test", "text": "Test Email"}'
```

### Test Médications :

```bash
# Rechercher médicament
curl -X GET "http://localhost:3000/api/medications/search?drugName=aspirin" \
  -H "Authorization: Bearer YOUR_TOKEN"

# Vérifier interactions
curl -X POST http://localhost:3000/api/medications/check-interactions \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"drugNames": ["aspirin", "warfarin"]}'

# Créer rappel
curl -X POST http://localhost:3000/api/medications/reminders \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "medication_name": "Aspirin",
    "dosage": "100mg",
    "frequency": "daily",
    "times_per_day": 1,
    "start_date": "2025-01-01"
  }'
```

---

## ✅ Étape 6 : Intégration dans l'Application Flutter

### 6.1 Ajouter les écrans à la navigation

Modifier le fichier de navigation principal (ex: `main.dart` ou `navigation.dart`) :

```dart
// Imports
import 'screens/contact_tracing_screen.dart';
import 'screens/dashboard_patient_screen.dart';
import 'screens/lab_results_screen.dart';
import 'screens/medication_reminders_screen.dart';

// Dans le routeur ou navigation
routes: {
  '/contact-tracing': (context) => const ContactTracingScreen(),
  '/dashboard-patient': (context) => const DashboardPatientScreen(),
  '/lab-results': (context) => const LabResultsScreen(),
  '/medication-reminders': (context) => const MedicationRemindersScreen(),
}
```

### 6.2 Ajouter les liens dans le menu principal

Ajouter des boutons/cartes dans le dashboard principal pour accéder aux nouvelles fonctionnalités.

### 6.3 Tester l'intégration

1. Démarrer l'app Flutter
2. Naviguer vers les nouveaux écrans
3. Tester les fonctionnalités :
   - Contact Tracing depuis un diagnostic
   - Dashboard Patient
   - Visualisation Résultats Labo
   - Gestion Rappels Médication

---

## ✅ Étape 7 : Permissions dans la Base de Données

S'assurer que les permissions sont configurées pour les nouvelles fonctionnalités :

```sql
-- Contact Tracing
INSERT OR IGNORE INTO permissions (role, resource, action) VALUES
  ('agent', 'diagnostics', 'read'),
  ('supervisor', 'diagnostics', 'read_all'),
  ('epidemiologist', 'diagnostics', 'read_all');

-- Notifications
INSERT OR IGNORE INTO permissions (role, resource, action) VALUES
  ('agent', 'notifications', 'create'),
  ('supervisor', 'notifications', 'create');

-- Médications
INSERT OR IGNORE INTO permissions (role, resource, action) VALUES
  ('agent', 'medications', 'create'),
  ('agent', 'medications', 'read'),
  ('agent', 'medications', 'update');
```

Ou exécuter :
```bash
cd backend
npm run init-db
```

---

## ✅ Étape 8 : Tests Complets

### Tests Backend :

1. **Contact Tracing** :
   - Créer plusieurs diagnostics avec positions GPS
   - Tester le traçage des contacts
   - Vérifier le calcul du R0
   - Générer un rapport d'investigation

2. **Notifications** :
   - Tester SMS avec Twilio
   - Tester WhatsApp (Twilio ou Meta)
   - Tester Email avec SMTP
   - Tester Push avec FCM
   - Tester envoi multicanaux

3. **Médications** :
   - Rechercher un médicament
   - Vérifier les interactions
   - Créer un rappel
   - Marquer un médicament comme pris
   - Consulter les statistiques d'observance

### Tests Flutter :

1. **Navigation** :
   - Vérifier que tous les écrans sont accessibles
   - Tester la navigation entre écrans

2. **Fonctionnalités** :
   - Contact Tracing : Afficher les contacts, R0, graphique
   - Dashboard Patient : Afficher stats, objectifs, diagnostics récents
   - Résultats Labo : Afficher valeurs, graphiques, interprétation
   - Rappels Médication : Créer, consulter, marquer comme pris

---

## ✅ Étape 9 : Documentation et Formation

### Pour les développeurs :

1. Documenter les APIs dans Swagger (déjà configuré)
2. Créer des exemples d'utilisation
3. Documenter les cas d'erreur

### Pour les utilisateurs :

1. Créer un guide d'utilisation
2. Enregistrer des tutoriels vidéo
3. Préparer une session de formation

---

## 🐛 Résolution de Problèmes

### Erreur "Module not found" :
```bash
cd backend
npm install
```

### Erreur "Table doesn't exist" :
```bash
cd backend
npm run init-db
```

### Erreur API "Unauthorized" :
- Vérifier que le token JWT est valide
- Vérifier les permissions dans la base de données

### Erreur Twilio/WhatsApp :
- Vérifier les credentials dans `.env`
- Vérifier que le compte Twilio est actif
- Pour WhatsApp, vérifier que Sandbox est activé

### Erreur SMTP :
- Vérifier les credentials email
- Pour Gmail, utiliser un "App Password"
- Vérifier que le port 587 n'est pas bloqué

---

## 📝 Checklist d'Intégration

- [ ] Dépendances backend installées
- [ ] Base de données initialisée
- [ ] Variables d'environnement configurées
- [ ] Serveur backend démarre sans erreur
- [ ] APIs testées avec curl/Postman
- [ ] Écrans Flutter ajoutés à la navigation
- [ ] Permissions configurées
- [ ] Tests complets effectués
- [ ] Documentation mise à jour
- [ ] Tests utilisateurs effectués

---

## 🎯 Prochaines Améliorations (Optionnel)

1. **Vidéoconsultation** :
   - Implémenter l'intégration Agora.io ou Twilio Video
   - Créer l'écran de consultation vidéo

2. **Intégration FHIR Complète** :
   - Compléter l'implémentation FHIR
   - Tester l'interopérabilité avec autres systèmes

3. **Dashboard Patient Avancé** :
   - Ajouter graphiques longitudinales
   - Ajouter objectifs personnalisés

4. **Résultats Labo Avancés** :
   - Parser automatique des fichiers HL7
   - Intégration avec laboratoires externes

---

*Document créé : Janvier 2025*
*Dernière mise à jour : Janvier 2025*

