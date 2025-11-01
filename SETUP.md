# Guide de Configuration M.A.D.E

## 🚀 Démarrage Rapide

### 1. Configuration du Backend

```bash
cd backend
npm install
cp env.example .env
npm run init-db
npm run dev
```

Le serveur backend sera accessible sur `http://localhost:3000`

### 2. Configuration du Frontend Flutter

```bash
cd healther
flutter pub get
flutter run
```

## 📝 Configuration détaillée

### Backend Node.js

#### Fichier .env
```
PORT=3000
NODE_ENV=development
DB_PATH=./data/made.db
UPLOAD_DIR=./uploads
```

#### Initialisation de la base de données
La base de données SQLite est automatiquement créée lors de l'exécution de `npm run init-db`.

Tables créées :
- `users` : Utilisateurs
- `diagnostics` : Diagnostics
- `epidemics` : Clusters épidémiques
- `daily_stats` : Statistiques quotidiennes

### Frontend Flutter

#### Dépendances principales
- `http` : Communication avec l'API
- `provider` : Gestion d'état
- `camera` : Accès à la caméra
- `image_picker` : Sélection d'images
- `geolocator` : Géolocalisation
- `geocoding` : Géocodage

#### Configuration API
Modifier l'URL de base dans `lib/services/api_service.dart` :
```dart
static const String baseUrl = 'http://localhost:3000/api';
// Pour Android Emulator, utiliser: 'http://10.0.2.2:3000/api'
// Pour iOS Simulator, utiliser: 'http://localhost:3000/api'
```

## 🔧 Dépannage

### Backend ne démarre pas
- Vérifier que Node.js est installé
- Vérifier que le port 3000 n'est pas déjà utilisé
- Vérifier les permissions sur le dossier `data/`

### Flutter ne se connecte pas au backend
- Vérifier que le backend est démarré
- Vérifier l'URL de base dans `api_service.dart`
- Pour Android Emulator, utiliser `10.0.2.2` au lieu de `localhost`
- Vérifier les permissions Internet dans AndroidManifest.xml

### Problèmes de permissions
- Vérifier les permissions dans AndroidManifest.xml
- Pour Android 13+, vérifier les permissions runtime

### Base de données
- Si la base de données est corrompue, supprimer `backend/data/made.db`
- Réexécuter `npm run init-db`

## 📱 Test sur appareil physique

1. Vérifier que l'appareil et l'ordinateur sont sur le même réseau WiFi
2. Trouver l'adresse IP locale de l'ordinateur
3. Modifier l'URL de base dans `api_service.dart` :
   ```dart
   static const String baseUrl = 'http://192.168.x.x:3000/api';
   ```
4. Démarrer le backend avec l'adresse IP :
   ```bash
   # Backend doit écouter sur toutes les interfaces
   # Modifier server.js si nécessaire
   ```


