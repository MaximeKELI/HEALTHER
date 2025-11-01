# 🔬 Guide d'Intégration ML Réel - M.A.D.E

## ✅ Ce qui a été implémenté

1. **Service ML Backend** (`backend/services/ml_service.js`)
   - Structure prête pour intégrer un modèle ML réel
   - Preprocessing d'images
   - Support pour paludisme, typhoïde et analyse mixte

2. **API ML** (`backend/routes/ml_analysis.js`)
   - Endpoint `/api/ml/analyze` pour l'analyse d'images
   - Endpoint `/api/ml/health` pour vérifier l'état du service

3. **Intégration Flutter**
   - Appel API ML depuis l'application Flutter
   - Pas de simulation, utilise le backend ML réel

4. **Authentification améliorée**
   - Bcrypt pour le hashage des mots de passe
   - JWT pour l'authentification sécurisée

## 🚀 Étapes pour intégrer un vrai modèle ML

### Option 1 : TensorFlow.js (Recommandé pour Node.js)

1. **Installer TensorFlow.js**
```bash
cd backend
npm install @tensorflow/tfjs-node
```

2. **Entraîner ou obtenir un modèle**
   - Entraîner un modèle avec TensorFlow/Keras
   - Convertir en format TensorFlow.js
   - Placer le modèle dans `backend/models/`

3. **Modifier `ml_service.js`**
```javascript
const tf = require('@tensorflow/tfjs-node');
const path = require('path');
const fs = require('fs');

class MLService {
  constructor() {
    this.model = null;
    this.modelLoaded = false;
  }

  async loadModel() {
    try {
      const modelPath = path.join(__dirname, '../models/malaria_model.json');
      if (fs.existsSync(modelPath)) {
        this.model = await tf.loadLayersModel(`file://${modelPath}`);
        this.modelLoaded = true;
        console.log('✅ Modèle TensorFlow chargé avec succès');
      }
    } catch (error) {
      console.error('❌ Erreur lors du chargement du modèle:', error);
    }
  }

  async analyzeMalaria(imageBuffer) {
    if (!this.model) {
      throw new Error('Modèle non chargé');
    }

    // Preprocesser l'image pour le modèle
    const preprocessed = this.preprocessForModel(imageBuffer);
    
    // Faire la prédiction
    const prediction = this.model.predict(preprocessed);
    const result = await prediction.data();
    
    // Interpréter les résultats
    return this.interpretResults(result);
  }
}
```

### Option 2 : Service Python séparé (Recommandé pour production)

1. **Créer un service Python avec Flask/FastAPI**

```python
# ml_service.py
from flask import Flask, request, jsonify
import tensorflow as tf
import numpy as np
from PIL import Image
import base64
import io

app = Flask(__name__)

# Charger le modèle
model = tf.keras.models.load_model('models/malaria_model.h5')

@app.route('/analyze', methods=['POST'])
def analyze():
    data = request.json
    image_base64 = data['image_base64']
    maladie_type = data['maladie_type']
    
    # Décoder et preprocesser l'image
    image_data = base64.b64decode(image_base64)
    image = Image.open(io.BytesIO(image_data))
    processed = preprocess_image(image, maladie_type)
    
    # Faire la prédiction
    prediction = model.predict(processed)
    
    # Retourner les résultats
    return jsonify({
        'detected': prediction[0] > 0.5,
        'confidence': float(prediction[0] * 100),
        'parasites_count': float(prediction[1]),
        'analysis_type': maladie_type,
    })

if __name__ == '__main__':
    app.run(port=5000)
```

2. **Modifier le backend Node.js pour appeler le service Python**

```javascript
// Dans ml_service.js
const axios = require('axios');

async analyzeImage(base64Image, maladieType) {
  try {
    const response = await axios.post('http://localhost:5000/analyze', {
      image_base64: base64Image,
      maladie_type: maladieType,
    });
    
    return response.data;
  } catch (error) {
    throw new Error(`Erreur ML Service: ${error.message}`);
  }
}
```

### Option 3 : API Cloud (Google Vision, AWS Rekognition)

```javascript
// Exemple avec Google Cloud Vision API
const vision = require('@google-cloud/vision');
const client = new vision.ImageAnnotatorClient();

async analyzeImage(base64Image, maladieType) {
  const image = {
    content: Buffer.from(base64Image, 'base64'),
  };
  
  // Utiliser l'API de détection d'objets
  const [result] = await client.objectLocalization(image);
  // Adapter selon vos besoins de diagnostic
  
  return interpretVisionAPI(result);
}
```

## 📦 Dépendances ajoutées

### Backend
- `bcrypt` : Hashage sécurisé des mots de passe
- `jsonwebtoken` : Tokens JWT pour l'authentification
- `@tensorflow/tfjs-node` : TensorFlow.js pour Node.js
- `sharp` : Traitement d'images performant

### Flutter
- `tflite_flutter` : TensorFlow Lite pour analyse offline (optionnel)

## 🔒 Authentification sécurisée

L'authentification utilise maintenant :
- **Bcrypt** : Hashage des mots de passe (salt rounds: 10)
- **JWT** : Tokens d'authentification (expiration: 24h)

### Utilisation dans l'API

```javascript
// Protéger une route
const { authenticateToken } = require('../middleware/auth');

router.get('/protected', authenticateToken, (req, res) => {
  // req.user contient les informations de l'utilisateur authentifié
  res.json({ user: req.user });
});
```

## 🎯 Prochaines étapes

1. **Obtenir ou entraîner un modèle ML**
   - Modèle pour paludisme
   - Modèle pour typhoïde
   - Validation avec dataset médical réel

2. **Intégrer le modèle**
   - Suivre l'une des options ci-dessus
   - Tester avec des images réelles
   - Ajuster le preprocessing si nécessaire

3. **Optimiser les performances**
   - Cache des résultats
   - Queue pour les analyses longues
   - Optimisation du modèle

4. **Validation médicale**
   - Tests avec professionnels de santé
   - Comparaison avec diagnostics réels
   - Ajustements selon les retours

## ⚠️ Notes importantes

- Le service ML actuel utilise une analyse basique (temporaire)
- Pour la production, intégrer un vrai modèle entraîné
- Valider médicalement avant déploiement
- Respecter les réglementations médicales locales

