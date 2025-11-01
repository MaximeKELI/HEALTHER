const express = require('express');
const router = express.Router();
const bcrypt = require('bcrypt');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { dbRun, dbGet, dbAll } = require('../config/database');
const { generateAccessToken, generateOpaqueToken, authenticateToken } = require('../middleware/auth');
const { checkPermission } = require('../middleware/permissions');
const dayjs = require('dayjs');
const storageService = require('../services/storage_service');
const imageQualityService = require('../services/image_quality_service');

// Multer configuration pour upload de photos de profil
const uploadsDir = path.join(__dirname, '..', 'uploads', 'profiles');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}

const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, uploadsDir);
  },
  filename: function (req, file, cb) {
    // Utiliser l'ID utilisateur depuis les params si req.user n'est pas encore disponible
    const userId = req.user?.id || req.params?.id || 'unknown';
    const unique = `profile-${userId}-${Date.now()}-${Math.round(Math.random() * 1e9)}`;
    const ext = path.extname(file.originalname) || '.jpg';
    cb(null, unique + ext);
  }
});

const upload = multer({
  storage,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB pour les photos de profil
  fileFilter: (req, file, cb) => {
    const allowed = ['image/jpeg', 'image/png', 'image/jpg', 'image/webp'];
    if (allowed.includes(file.mimetype)) return cb(null, true);
    cb(new Error('Type de fichier non supporté. Utilisez JPEG, PNG ou WebP'));
  }
});

// Créer un nouvel utilisateur avec hashage bcrypt
router.post('/register', async (req, res) => {
  try {
    const { username, email, password, nom, prenom, centre_sante, role = 'agent' } = req.body;

    if (!username || !email || !password) {
      return res.status(400).json({ error: 'username, email et password sont requis' });
    }

    // Validation du mot de passe
    if (password.length < 6) {
      return res.status(400).json({ error: 'Le mot de passe doit contenir au moins 6 caractères' });
    }

    // Vérifier si l'utilisateur existe déjà
    const existing = await dbGet('SELECT * FROM users WHERE username = ? OR email = ?', [username, email]);
    if (existing) {
      return res.status(409).json({ error: 'Un utilisateur avec ce nom ou email existe déjà' });
    }

    // Hasher le mot de passe avec bcrypt
    const saltRounds = 10;
    const password_hash = await bcrypt.hash(password, saltRounds);

    const result = await dbRun(
      `INSERT INTO users (username, email, password_hash, nom, prenom, centre_sante, role)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [username, email, password_hash, nom || null, prenom || null, centre_sante || null, role]
    );

    // Récupérer l'utilisateur créé
    const newUser = await dbGet('SELECT id, username, email, nom, prenom, centre_sante, role, profile_picture, created_at FROM users WHERE id = ?', [result.lastID]);

    // Générer tokens
    const accessToken = generateAccessToken(newUser);
    const refreshToken = generateOpaqueToken();
    const bcryptHash = await bcrypt.hash(refreshToken, 10);
    await dbRun(
      `INSERT INTO refresh_tokens (user_id, token_hash, expires_at) VALUES (?, ?, ?)`,
      [newUser.id, bcryptHash, dayjs().add(30, 'day').toISOString()]
    );

    // Générer URL signée si profile_picture existe
    if (newUser.profile_picture) {
      try {
        newUser.profile_picture_url = await storageService.getSignedUrl(newUser.profile_picture, 3600);
      } catch (e) {
        console.error('Erreur génération URL signée:', e);
      }
    }

    res.status(201).json({
      user: newUser,
      token: accessToken,
      refresh_token: refreshToken,
      message: 'Utilisateur créé avec succès'
    });
  } catch (error) {
    console.error('Erreur lors de la création de l\'utilisateur:', error);
    res.status(500).json({ error: 'Erreur serveur lors de la création de l\'utilisateur' });
  }
});

// Authentification avec bcrypt et JWT
router.post('/login', async (req, res) => {
  try {
    const { username, password } = req.body;

    if (!username || !password) {
      return res.status(400).json({ error: 'username et password sont requis' });
    }

    // Récupérer l'utilisateur
    const user = await dbGet('SELECT * FROM users WHERE username = ?', [username]);
    
    if (!user) {
      return res.status(401).json({ error: 'Identifiants incorrects' });
    }

    // Vérifier le mot de passe avec bcrypt
    const passwordMatch = await bcrypt.compare(password, user.password_hash);
    
    if (!passwordMatch) {
      return res.status(401).json({ error: 'Identifiants incorrects' });
    }

    // Vérifier 2FA si activé
    if (user.totp_enabled) {
      const { totp_code } = req.body;
      if (!totp_code) {
        return res.status(400).json({ 
          error: 'Code 2FA requis',
          requires_2fa: true 
        });
      }
      
      const totpService = require('../services/totp_service');
      const totpValid = await totpService.verifyTOTP(user.id, totp_code);
      
      if (!totpValid) {
        return res.status(401).json({ error: 'Code 2FA invalide' });
      }
    }

    // Retirer le password_hash de la réponse
    const { password_hash: _, ...userWithoutPassword } = user;

    // Générer tokens
    const accessToken = generateAccessToken(user);
    const refreshToken = generateOpaqueToken();
    const bcryptHash = await bcrypt.hash(refreshToken, 10);
    await dbRun(
      `INSERT INTO refresh_tokens (user_id, token_hash, expires_at) VALUES (?, ?, ?)`,
      [user.id, bcryptHash, dayjs().add(30, 'day').toISOString()]
    );

    // Générer URL signée si profile_picture existe
    if (userWithoutPassword.profile_picture) {
      try {
        userWithoutPassword.profile_picture_url = await storageService.getSignedUrl(userWithoutPassword.profile_picture, 3600);
      } catch (e) {
        console.error('Erreur génération URL signée:', e);
      }
    }

    res.json({
      user: userWithoutPassword,
      token: accessToken,
      refresh_token: refreshToken,
      message: 'Connexion réussie'
    });
  } catch (error) {
    console.error('Erreur lors de l\'authentification:', error);
    res.status(500).json({ error: 'Erreur serveur lors de l\'authentification' });
  }
});

// Obtenir tous les utilisateurs (protégé)
router.get('/', authenticateToken, checkPermission('users', 'read'), async (req, res) => {
  try {
    const users = await dbAll('SELECT id, username, email, nom, prenom, centre_sante, role, profile_picture, created_at FROM users');
    
    // Ajouter les URLs signées pour les photos de profil
    for (const user of users) {
      if (user.profile_picture) {
        try {
          user.profile_picture_url = await storageService.getSignedUrl(user.profile_picture, 3600);
        } catch (e) {
          console.error('Erreur génération URL signée:', e);
        }
      }
    }
    
    res.json(users);
  } catch (error) {
    console.error('Erreur lors de la récupération des utilisateurs:', error);
    res.status(500).json({ error: 'Erreur serveur lors de la récupération des utilisateurs' });
  }
});

// Obtenir un utilisateur spécifique (protégé)
router.get('/:id', authenticateToken, checkPermission('users', 'read'), async (req, res) => {
  try {
    const { id } = req.params;
    const user = await dbGet('SELECT id, username, email, nom, prenom, centre_sante, role, profile_picture, created_at FROM users WHERE id = ?', [id]);

    if (!user) {
      return res.status(404).json({ error: 'Utilisateur non trouvé' });
    }

    // Générer URL signée si profile_picture existe
    if (user.profile_picture) {
      try {
        user.profile_picture_url = await storageService.getSignedUrl(user.profile_picture, 3600);
      } catch (e) {
        console.error('Erreur génération URL signée:', e);
      }
    }

    res.json(user);
  } catch (error) {
    console.error('Erreur lors de la récupération de l\'utilisateur:', error);
    res.status(500).json({ error: 'Erreur serveur lors de la récupération de l\'utilisateur' });
  }
});

// Upload/Mise à jour photo de profil
router.put('/:id/profile-picture', authenticateToken, upload.single('profile_picture'), async (req, res) => {
  try {
    const { id } = req.params;
    const userId = parseInt(id);
    
    // Vérifier que l'utilisateur modifie son propre profil ou est admin
    if (userId !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({ error: 'Vous ne pouvez modifier que votre propre profil' });
    }

    if (!req.file) {
      return res.status(400).json({ error: 'Aucun fichier fourni' });
    }

    // Lire le buffer du fichier
    const fileBuffer = fs.readFileSync(req.file.path);
    
    // Analyser la qualité de l'image
    const qualityMetrics = await imageQualityService.analyzeImageQuality(fileBuffer);
    
    // Upload vers S3/MinIO ou stockage local
    const storedKey = await storageService.uploadFile(
      fileBuffer,
      req.file.originalname,
      req.file.mimetype,
      'profiles'
    );
    
    // Supprimer le fichier local temporaire
    fs.unlinkSync(req.file.path);

    // Supprimer l'ancienne photo si elle existe
    const currentUser = await dbGet('SELECT profile_picture FROM users WHERE id = ?', [userId]);
    if (currentUser?.profile_picture) {
      try {
        await storageService.deleteFile(currentUser.profile_picture);
      } catch (e) {
        console.error('Erreur suppression ancienne photo:', e);
      }
    }

    // Mettre à jour la base de données
    await dbRun('UPDATE users SET profile_picture = ? WHERE id = ?', [storedKey, userId]);

    // Générer URL signée
    const signedUrl = await storageService.getSignedUrl(storedKey, 3600);

    res.json({
      message: 'Photo de profil mise à jour avec succès',
      profile_picture: storedKey,
      profile_picture_url: signedUrl,
      quality_metrics: qualityMetrics
    });
  } catch (error) {
    console.error('Erreur lors de la mise à jour de la photo de profil:', error);
    
    // Nettoyer le fichier uploadé en cas d'erreur
    if (req.file && fs.existsSync(req.file.path)) {
      fs.unlinkSync(req.file.path);
    }
    
    res.status(500).json({ error: 'Erreur serveur lors de la mise à jour de la photo de profil' });
  }
});

// Supprimer la photo de profil
router.delete('/:id/profile-picture', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const userId = parseInt(id);
    
    // Vérifier que l'utilisateur modifie son propre profil ou est admin
    if (userId !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({ error: 'Vous ne pouvez modifier que votre propre profil' });
    }

    // Récupérer l'utilisateur actuel
    const user = await dbGet('SELECT profile_picture FROM users WHERE id = ?', [userId]);
    
    if (!user || !user.profile_picture) {
      return res.status(404).json({ error: 'Aucune photo de profil trouvée' });
    }

    // Supprimer le fichier du stockage
    try {
      await storageService.deleteFile(user.profile_picture);
    } catch (e) {
      console.error('Erreur suppression fichier:', e);
    }

    // Mettre à jour la base de données
    await dbRun('UPDATE users SET profile_picture = NULL WHERE id = ?', [userId]);

    res.json({ message: 'Photo de profil supprimée avec succès' });
  } catch (error) {
    console.error('Erreur lors de la suppression de la photo de profil:', error);
    res.status(500).json({ error: 'Erreur serveur lors de la suppression de la photo de profil' });
  }
});

// Rafraîchir le token d'accès
router.post('/refresh', async (req, res) => {
  try {
    const { refresh_token } = req.body || {};
    if (!refresh_token) return res.status(400).json({ error: 'refresh_token requis' });

    // Trouver un refresh valide pour cet utilisateur
    const tokenRows = await dbAll('SELECT * FROM refresh_tokens WHERE revoked_at IS NULL AND expires_at > CURRENT_TIMESTAMP');
    let matched = null;
    for (const row of tokenRows) {
      const ok = await bcrypt.compare(refresh_token, row.token_hash);
      if (ok) { matched = row; break; }
    }
    if (!matched) return res.status(403).json({ error: 'Refresh token invalide' });

    // Récupérer l'utilisateur
    const user = await dbGet('SELECT id, username, role FROM users WHERE id = ?', [matched.user_id]);
    if (!user) return res.status(403).json({ error: 'Utilisateur introuvable' });

    // Rotation: révoquer l'ancien et créer un nouveau
    await dbRun('UPDATE refresh_tokens SET revoked_at = CURRENT_TIMESTAMP WHERE id = ?', [matched.id]);
    const newRefresh = require('../middleware/auth').generateOpaqueToken();
    const newHash = await bcrypt.hash(newRefresh, 10);
    await dbRun('INSERT INTO refresh_tokens (user_id, token_hash, expires_at) VALUES (?, ?, ?)', [user.id, newHash, require('dayjs')().add(30, 'day').toISOString()]);

    const accessToken = require('../middleware/auth').generateAccessToken(user);
    res.json({ token: accessToken, refresh_token: newRefresh });
  } catch (error) {
    console.error('Erreur refresh token:', error);
    res.status(500).json({ error: 'Erreur serveur lors du refresh' });
  }
});

// Logout: révoquer un refresh token
router.post('/logout', authenticateToken, async (req, res) => {
  try {
    const { refresh_token } = req.body || {};
    if (!refresh_token) return res.status(400).json({ error: 'refresh_token requis' });
    const rows = await dbAll('SELECT * FROM refresh_tokens WHERE revoked_at IS NULL');
    for (const row of rows) {
      const ok = await bcrypt.compare(refresh_token, row.token_hash);
      if (ok && row.user_id === req.user.id) {
        await dbRun('UPDATE refresh_tokens SET revoked_at = CURRENT_TIMESTAMP WHERE id = ?', [row.id]);
        return res.json({ message: 'Déconnecté' });
      }
    }
    res.status(403).json({ error: 'Refresh token invalide' });
  } catch (error) {
    console.error('Erreur logout:', error);
    res.status(500).json({ error: 'Erreur serveur lors du logout' });
  }
});

module.exports = router;


