# 🚀 Guide de Démarrage Rapide - M.A.D.E

## Étape 1 : Configuration du Backend

```bash
# Aller dans le dossier backend
cd backend

# Installer les dépendances Node.js
npm install

# Créer le fichier .env (si nécessaire)
# PORT=3000
# NODE_ENV=development
# DB_PATH=./data/made.db
# UPLOAD_DIR=./uploads

# Initialiser la base de données
npm run init-db

# Créer un utilisateur de test (optionnel)
npm run create-user

# Démarrer le serveur en mode développement
npm run dev
```

✅ Le serveur backend sera accessible sur `http://localhost:3000`

## Étape 2 : Configuration du Frontend Flutter

Ouvrir un nouveau terminal :

```bash
# Aller dans le dossier Flutter
cd healther

# Installer les dépendances Flutter
flutter pub get

# Vérifier la configuration
# Modifier l'URL de base dans lib/services/api_service.dart si nécessaire
# Pour Android Emulator : 'http://10.0.2.2:3000/api'
# Pour iOS Simulator : 'http://localhost:3000/api'
# Pour appareil physique : 'http://[ADRESSE_IP]:3000/api'

# Démarrer l'application
flutter run
```

## 🎯 Premier Utilisateur

Pour créer votre premier utilisateur :

### Option 1 : Via le script
```bash
cd backend
npm run create-user
```

### Option 2 : Via l'API (curl)
```bash
curl -X POST http://localhost:3000/api/users/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "email": "test@example.com",
    "password_hash": "password123",
    "nom": "Test",
    "prenom": "User",
    "centre_sante": "Centre Test",
    "role": "agent"
  }'
```

## 📱 Utilisation de l'Application

1. **Connexion** : Utiliser les identifiants créés
2. **Diagnostic** :
   - Sélectionner le type de maladie
   - Prendre une photo ou choisir depuis la galerie
   - L'application analyse l'image (simulation IA)
   - Enregistrer le diagnostic
3. **Historique** : Consulter tous les diagnostics
4. **Dashboard** : Voir les statistiques et clusters épidémiques

## 🔧 Configuration des Permissions

### Android
Les permissions sont déjà configurées dans `AndroidManifest.xml` :
- Caméra
- Géolocalisation
- Stockage
- Internet

### iOS
Ajouter dans `Info.plist` :
```xml
<key>NSCameraUsageDescription</key>
<string>L'application a besoin d'accéder à la caméra pour prendre des photos de diagnostic</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>L'application a besoin de votre localisation pour géolocaliser les diagnostics</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>L'application a besoin d'accéder à votre galerie pour sélectionner des images</string>
```

## ⚠️ Notes Importantes

1. **POC/MVP** : Cette version est un Proof of Concept
2. **Authentification** : Les mots de passe sont stockés en clair (à améliorer en production)
3. **IA** : L'analyse d'images est simulée (à remplacer par un vrai modèle)
4. **Base de données** : SQLite pour le développement (migrer vers PostgreSQL pour la production)
5. **URL Backend** : Ajuster selon l'environnement (emulateur, simulateur, appareil physique)

## 🐛 Dépannage

### Backend ne démarre pas
- Vérifier Node.js : `node --version`
- Vérifier le port 3000 : `lsof -i :3000` (Linux/Mac) ou `netstat -ano | findstr :3000` (Windows)
- Vérifier les logs dans la console

### Flutter ne se connecte pas
- Vérifier que le backend est démarré
- Vérifier l'URL dans `api_service.dart`
- Pour Android Emulator, utiliser `10.0.2.2` au lieu de `localhost`
- Vérifier les permissions Internet dans AndroidManifest.xml

### Erreurs de permissions
- Android : Vérifier `AndroidManifest.xml`
- iOS : Ajouter les clés dans `Info.plist`
- Appareil physique : Autoriser les permissions dans les paramètres

### Base de données
- Supprimer `backend/data/made.db` si corrompu
- Réexécuter `npm run init-db`

## 📞 Support

Pour plus d'informations, consulter le README.md principal.


