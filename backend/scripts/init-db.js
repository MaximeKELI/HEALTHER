const sqlite3 = require('sqlite3').verbose();
const fs = require('fs');
const path = require('path');

// Créer le dossier data s'il n'existe pas
const dataDir = path.join(__dirname, '..', 'data');
if (!fs.existsSync(dataDir)) {
  fs.mkdirSync(dataDir, { recursive: true });
}

const dbPath = path.join(dataDir, 'made.db');
const db = new sqlite3.Database(dbPath);

db.serialize(() => {
  // Table des utilisateurs (agents de santé)
  db.run(`CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT UNIQUE NOT NULL,
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    role TEXT NOT NULL DEFAULT 'agent',
    nom TEXT,
    prenom TEXT,
    centre_sante TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  )`);

  // Colonnes manquantes sur users (migration souple)
  db.all(`PRAGMA table_info(users)`, (err, rows) => {
    if (err) return console.error('PRAGMA users error:', err);
    const cols = rows.map(r => r.name);
    const addColumn = (name, type) => {
      if (!cols.includes(name)) {
        db.run(`ALTER TABLE users ADD COLUMN ${name} ${type}`);
        console.log(`➡️  Colonne ajoutée: users.${name}`);
      }
    };
    addColumn('profile_picture', 'TEXT');
    addColumn('totp_enabled', 'BOOLEAN DEFAULT 0');
  });

  // Table des diagnostics
  db.run(`CREATE TABLE IF NOT EXISTS diagnostics (
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
  )`);

  // Table des clusters épidémiques (pour la surveillance)
  db.run(`CREATE TABLE IF NOT EXISTS epidemics (
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
  )`);

  // Table des statistiques journalières (pour le dashboard)
  db.run(`CREATE TABLE IF NOT EXISTS daily_stats (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    date DATE NOT NULL,
    region TEXT,
    maladie_type TEXT NOT NULL,
    cas_positifs INTEGER DEFAULT 0,
    cas_negatifs INTEGER DEFAULT 0,
    cas_totaux INTEGER DEFAULT 0,
    taux_positivite REAL,
    UNIQUE(date, region, maladie_type)
  )`);

  // Table des refresh tokens (auth JWT rotation)
  db.run(`CREATE TABLE IF NOT EXISTS refresh_tokens (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    token_hash TEXT NOT NULL,
    expires_at DATETIME NOT NULL,
    revoked_at DATETIME,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
  )`);

  // Table des permissions (pour rôles avancés)
  db.run(`CREATE TABLE IF NOT EXISTS permissions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    role TEXT NOT NULL,
    resource TEXT NOT NULL,
    action TEXT NOT NULL,
    allowed BOOLEAN DEFAULT 1,
    UNIQUE(role, resource, action)
  )`);

  // Table d'audit (journal d'accès)
  db.run(`CREATE TABLE IF NOT EXISTS audit_log (
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
  )`);

  // Table des échantillons (suivi labo)
  db.run(`CREATE TABLE IF NOT EXISTS samples (
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
  )`);

  // Table des établissements de santé
  db.run(`CREATE TABLE IF NOT EXISTS health_centers (
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
  )`);

  // Table des conversations chatbot
  db.run(`CREATE TABLE IF NOT EXISTS chatbot_conversations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    title TEXT NOT NULL,
    closed_at DATETIME,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
  )`);

  // Table des messages chatbot
  db.run(`CREATE TABLE IF NOT EXISTS chatbot_messages (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    conversation_id INTEGER NOT NULL,
    role TEXT NOT NULL CHECK(role IN ('user', 'assistant')),
    message TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (conversation_id) REFERENCES chatbot_conversations(id)
  )`);

  // Table de feedback ML (amélioration modèles)
  db.run(`CREATE TABLE IF NOT EXISTS ml_feedback (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    diagnostic_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    predicted_result BOOLEAN,
    actual_result BOOLEAN,
    confidence REAL,
    feedback_type TEXT CHECK(feedback_type IN ('correct', 'incorrect', 'uncertain')),
    comments TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (diagnostic_id) REFERENCES diagnostics(id),
    FOREIGN KEY (user_id) REFERENCES users(id)
  )`);

  // Table de file d'attente offline (sync)
  db.run(`CREATE TABLE IF NOT EXISTS offline_queue (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    action TEXT NOT NULL,
    resource TEXT NOT NULL,
    data JSON NOT NULL,
    status TEXT DEFAULT 'pending' CHECK(status IN ('pending', 'syncing', 'synced', 'failed')),
    retry_count INTEGER DEFAULT 0,
    last_error TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    synced_at DATETIME,
    FOREIGN KEY (user_id) REFERENCES users(id)
  )`);

  // Table de notifications
  db.run(`CREATE TABLE IF NOT EXISTS notifications (
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
  )`);

  // Table de commentaires/discussions
  db.run(`CREATE TABLE IF NOT EXISTS comments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    diagnostic_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    comment TEXT NOT NULL,
    parent_id INTEGER,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (diagnostic_id) REFERENCES diagnostics(id),
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (parent_id) REFERENCES comments(id)
  )`);

  // Table de pièces jointes multiples
  db.run(`CREATE TABLE IF NOT EXISTS attachments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    diagnostic_id INTEGER NOT NULL,
    file_path TEXT NOT NULL,
    file_type TEXT,
    file_size INTEGER,
    mime_type TEXT,
    description TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (diagnostic_id) REFERENCES diagnostics(id)
  )`);

  // Table de géofencing (zones d'alerte)
  db.run(`CREATE TABLE IF NOT EXISTS geofences (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    region TEXT,
    prefecture TEXT,
    latitude REAL,
    longitude REAL,
    radius REAL,
    threshold_cases INTEGER DEFAULT 10,
    threshold_days INTEGER DEFAULT 7,
    maladie_type TEXT,
    active BOOLEAN DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  )`);

  // Table de campagnes
  db.run(`CREATE TABLE IF NOT EXISTS campaigns (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    type TEXT CHECK(type IN ('spraying', 'awareness', 'vaccination', 'screening')),
    region TEXT,
    start_date DATE,
    end_date DATE,
    status TEXT DEFAULT 'planned' CHECK(status IN ('planned', 'active', 'completed', 'cancelled')),
    description TEXT,
    resources_needed JSON,
    created_by INTEGER,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by) REFERENCES users(id)
  )`);

  // Table de rapports
  db.run(`CREATE TABLE IF NOT EXISTS reports (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    type TEXT NOT NULL CHECK(type IN ('weekly', 'monthly', 'custom')),
    region TEXT,
    date_start DATE,
    date_end DATE,
    generated_by INTEGER,
    file_path TEXT,
    parameters JSON,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (generated_by) REFERENCES users(id)
  )`);

  // Table de rendez-vous patients
  db.run(`CREATE TABLE IF NOT EXISTS appointments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    diagnostic_id INTEGER,
    patient_name TEXT,
    patient_phone TEXT,
    appointment_date DATETIME NOT NULL,
    status TEXT DEFAULT 'scheduled' CHECK(status IN ('scheduled', 'confirmed', 'completed', 'cancelled')),
    reminder_sent BOOLEAN DEFAULT 0,
    notes TEXT,
    created_by INTEGER,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (diagnostic_id) REFERENCES diagnostics(id),
    FOREIGN KEY (created_by) REFERENCES users(id)
  )`);

  // Table de suivi traitement (observance)
  db.run(`CREATE TABLE IF NOT EXISTS treatment_followup (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    diagnostic_id INTEGER NOT NULL,
    appointment_id INTEGER,
    treatment_started DATE,
    treatment_days INTEGER,
    adherence_percentage REAL,
    side_effects TEXT,
    outcome TEXT,
    followup_date DATE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (diagnostic_id) REFERENCES diagnostics(id),
    FOREIGN KEY (appointment_id) REFERENCES appointments(id)
  )`);

  // Table de rappels de médicaments
  db.run(`CREATE TABLE IF NOT EXISTS medication_reminders (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    medication_name TEXT NOT NULL,
    dosage TEXT,
    frequency TEXT DEFAULT 'daily',
    times_per_day INTEGER DEFAULT 1,
    start_date DATE NOT NULL,
    end_date DATE,
    notes TEXT,
    interaction_warnings TEXT,
    status TEXT DEFAULT 'active',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
  )`);

  // Table d'observance des médicaments
  db.run(`CREATE TABLE IF NOT EXISTS medication_adherence (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    reminder_id INTEGER NOT NULL,
    taken_at DATETIME NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (reminder_id) REFERENCES medication_reminders(id)
  )`);

  // Table de versions de modèles ML
  db.run(`CREATE TABLE IF NOT EXISTS ml_model_versions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    version TEXT NOT NULL UNIQUE,
    model_path TEXT,
    model_type TEXT,
    training_date DATE,
    accuracy REAL,
    precision REAL,
    recall REAL,
    f1_score REAL,
    active BOOLEAN DEFAULT 0,
    metadata JSON,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  )`);

  // Index pour améliorer les performances
  db.run(`CREATE INDEX IF NOT EXISTS idx_diagnostics_user ON diagnostics(user_id)`);
  db.run(`CREATE INDEX IF NOT EXISTS idx_diagnostics_date ON diagnostics(created_at)`);
  db.run(`CREATE INDEX IF NOT EXISTS idx_diagnostics_location ON diagnostics(latitude, longitude)`);
  db.run(`CREATE INDEX IF NOT EXISTS idx_diagnostics_maladie ON diagnostics(maladie_type)`);
  db.run(`CREATE INDEX IF NOT EXISTS idx_epidemics_region ON epidemics(region)`);
  db.run(`CREATE INDEX IF NOT EXISTS idx_audit_user ON audit_log(user_id)`);
  db.run(`CREATE INDEX IF NOT EXISTS idx_audit_date ON audit_log(created_at)`);
  db.run(`CREATE INDEX IF NOT EXISTS idx_samples_diagnostic ON samples(diagnostic_id)`);
  db.run(`CREATE INDEX IF NOT EXISTS idx_samples_barcode ON samples(barcode)`);
  db.run(`CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id, read)`);
  db.run(`CREATE INDEX IF NOT EXISTS idx_offline_queue_user ON offline_queue(user_id, status)`);
  db.run(`CREATE INDEX IF NOT EXISTS idx_comments_diagnostic ON comments(diagnostic_id)`);
  db.run(`CREATE INDEX IF NOT EXISTS idx_geofences_active ON geofences(active)`);
  db.run(`CREATE INDEX IF NOT EXISTS idx_chatbot_conversations_user ON chatbot_conversations(user_id, closed_at)`);
  db.run(`CREATE INDEX IF NOT EXISTS idx_chatbot_messages_conversation ON chatbot_messages(conversation_id, created_at)`);
  db.run(`CREATE INDEX IF NOT EXISTS idx_medication_reminders_user ON medication_reminders(user_id, status)`);
  db.run(`CREATE INDEX IF NOT EXISTS idx_medication_adherence_reminder ON medication_adherence(reminder_id, taken_at)`);

  // Données initiales - Permissions par rôle
  db.run(`INSERT OR IGNORE INTO permissions (role, resource, action) VALUES
    ('agent', 'diagnostics', 'create'),
    ('agent', 'diagnostics', 'read_own'),
    ('supervisor', 'diagnostics', 'read_all'),
    ('supervisor', 'diagnostics', 'update'),
    ('epidemiologist', 'diagnostics', 'read_all'),
    ('epidemiologist', 'dashboard', 'read'),
    ('epidemiologist', 'reports', 'create'),
    ('agent', 'medications', 'create'),
    ('agent', 'medications', 'read'),
    ('agent', 'medications', 'update'),
    ('supervisor', 'medications', 'read_all'),
    ('agent', 'notifications', 'create'),
    ('supervisor', 'notifications', 'create'),
    ('epidemiologist', 'notifications', 'create'),
    ('admin', '*', '*')`);

  // Données initiales - Centres de santé (exemples)
  db.run(`INSERT OR IGNORE INTO health_centers (name, type, region, prefecture) VALUES
    ('CHU Sylvanus Olympio', 'CHU', 'Lomé', 'Golfe'),
    ('CHR Kara', 'CHR', 'Kara', 'Kara'),
    ('CHR Sokodé', 'CHR', 'Centrale', 'Tchaoudjo')`);

  console.log('✅ Base de données initialisée avec succès');
  console.log(`📍 Base de données: ${dbPath}`);
});

db.close((err) => {
  if (err) {
    console.error('❌ Erreur lors de la fermeture de la base de données:', err);
  } else {
    console.log('✅ Connexion à la base de données fermée');
  }
});


