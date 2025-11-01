require('dotenv').config();
const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const path = require('path');
const fs = require('fs');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
const http = require('http');
const { Server } = require('socket.io');
const jwt = require('jsonwebtoken');
const { authenticateToken } = require('./middleware/auth');

const app = express();
const server = http.createServer(app);
// CORS whitelist depuis env (ALLOWED_ORIGINS= http://localhost:3000,http://localhost:5173)
const allowedOrigins = (process.env.ALLOWED_ORIGINS || '*')
  .split(',')
  .map(o => o.trim())
  .filter(Boolean);

const io = new Server(server, {
  cors: {
    origin: allowedOrigins.length === 1 && allowedOrigins[0] === '*' ? '*' : allowedOrigins,
    methods: ['GET', 'POST']
  }
});

const PORT = process.env.PORT || 3000;

// Middleware
app.set('trust proxy', 1);
app.use(cors({
  origin: allowedOrigins.length === 1 && allowedOrigins[0] === '*' ? '*': allowedOrigins,
  methods: ['GET','HEAD','PUT','PATCH','POST','DELETE'],
  credentials: false
}));
app.use(helmet());
if (process.env.NODE_ENV !== 'production') {
  app.use(morgan('dev'));
}
const limiter = rateLimit({ windowMs: 60 * 1000, max: 100 });
app.use(limiter);
app.use(bodyParser.json({ limit: '50mb' }));
app.use(bodyParser.urlencoded({ extended: true, limit: '50mb' }));

// Routes
const diagnosticsRoutes = require('./routes/diagnostics');
const dashboardRoutes = require('./routes/dashboard');
const usersRoutes = require('./routes/users');
const mlRoutes = require('./routes/ml_analysis');
const samplesRoutes = require('./routes/samples');
const mlFeedbackRoutes = require('./routes/ml_feedback');
const offlineQueueRoutes = require('./routes/offline_queue');
const notificationsRoutes = require('./routes/notifications');
const geofencingRoutes = require('./routes/geofencing');
const campaignsRoutes = require('./routes/campaigns');
const commentsRoutes = require('./routes/comments');
const reportsRoutes = require('./routes/reports');
const appointmentsRoutes = require('./routes/appointments');
const healthCentersRoutes = require('./routes/health_centers');
const totpRoutes = require('./routes/totp');
const patientHistoryRoutes = require('./routes/patient_history');
const searchRoutes = require('./routes/search');
const taskRoutes = require('./routes/tasks');
const chatRoutes = require('./routes/chat');
const chatbotRoutes = require('./routes/chatbot');
const monitoringRoutes = require('./routes/monitoring');
const fhirRoutes = require('./routes/fhir');
const voiceAssistantRoutes = require('./routes/voice_assistant');
const predictionRoutes = require('./routes/prediction');
const alertsRoutes = require('./routes/alerts');

// Importer monitoringService APRÈS les autres routes
const monitoringService = require('./services/monitoring_service');
// Middleware de monitoring (doit être après l'import)
app.use(monitoringService.monitoringMiddleware);
const swaggerUi = require('swagger-ui-express');
const swaggerDocument = require('./swagger.json');

app.use('/api/diagnostics', diagnosticsRoutes);
app.use('/api/dashboard', dashboardRoutes);
app.use('/api/users', usersRoutes);
app.use('/api/ml', mlRoutes);
app.use('/api/samples', samplesRoutes);
app.use('/api/ml-feedback', mlFeedbackRoutes);
app.use('/api/offline-queue', offlineQueueRoutes);
app.use('/api/notifications', notificationsRoutes);
app.use('/api/geofencing', geofencingRoutes);
app.use('/api/campaigns', campaignsRoutes);
app.use('/api/comments', commentsRoutes);
app.use('/api/reports', reportsRoutes);
app.use('/api/appointments', appointmentsRoutes);
app.use('/api/health-centers', healthCentersRoutes);
app.use('/api/totp', totpRoutes);
app.use('/api/patient-history', patientHistoryRoutes);
app.use('/api/search', searchRoutes);
app.use('/api/tasks', taskRoutes);
app.use('/api/chat', chatRoutes);
app.use('/api/chatbot', chatbotRoutes);
app.use('/api/monitoring', monitoringRoutes);
app.use('/api/fhir', fhirRoutes);
app.use('/api/voice-assistant', voiceAssistantRoutes);
app.use('/api/prediction', predictionRoutes);
app.use('/api/alerts', alertsRoutes);
app.use('/metrics', monitoringRoutes);
app.use('/docs', swaggerUi.serve, swaggerUi.setup(swaggerDocument));

// Route de santé (health check)
app.get('/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    message: 'M.A.D.E API est opérationnelle',
    timestamp: new Date().toISOString()
  });
});

// Route racine
app.get('/', (req, res) => {
  res.json({
    message: 'API M.A.D.E - Modèle d\'Aide au Diagnostic et à l\'Épidémiosurveillance',
    version: '1.0.0',
    endpoints: {
      health: '/health',
      diagnostics: '/api/diagnostics',
      dashboard: '/api/dashboard',
      users: '/api/users'
    }
  });
});

// Gestion des erreurs 404
app.use((req, res) => {
  res.status(404).json({ error: 'Route non trouvée' });
});

// Gestion des erreurs serveur
app.use((err, req, res, next) => {
  console.error('Erreur serveur:', err);
  res.status(500).json({ error: 'Erreur serveur interne' });
});

// WebSocket pour notifications en temps réel
io.on('connection', (socket) => {
  console.log('🔌 Client WebSocket connecté:', socket.id);
  // Vérifier le JWT fourni dans handshake.auth.token ou query.token
  try {
    const token = socket.handshake.auth?.token || socket.handshake.query?.token;
    if (!token) {
      console.warn('WS: token manquant, déconnexion');
      return socket.disconnect(true);
    }
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'your-secret-key-change-in-production');
    socket.user = decoded;
  } catch (err) {
    console.warn('WS: token invalide, déconnexion');
    return socket.disconnect(true);
  }

  socket.on('join-user-room', (userId) => {
    // Empêcher d'adhérer à une room d'un autre utilisateur
    if (!socket.user || String(userId) !== String(socket.user.id)) {
      return;
    }
    socket.join(`user-${userId}`);
    console.log(`👤 Utilisateur ${userId} rejoint sa room`);
  });
  
  // Joindre une room de diagnostic pour le chat
  socket.on('join-diagnostic-room', (diagnosticId) => {
    socket.join(`diagnostic-${diagnosticId}`);
    console.log(`📋 Utilisateur ${socket.user.id} rejoint le chat du diagnostic ${diagnosticId}`);
  });
  
  socket.on('disconnect', () => {
    console.log('🔌 Client WebSocket déconnecté:', socket.id);
  });
});

// Middleware pour exposer io dans req
app.use((req, res, next) => {
  req.io = io;
  next();
});

// Démarrer le serveur
server.listen(PORT, () => {
  console.log(`🚀 Serveur M.A.D.E démarré sur le port ${PORT}`);
  console.log(`📍 API disponible à: http://localhost:${PORT}`);
  console.log(`💚 Health check: http://localhost:${PORT}/health`);
  
  // Créer les dossiers nécessaires
  const dataDir = path.join(__dirname, 'data');
  const uploadsDir = path.join(__dirname, 'uploads');
  const reportsDir = path.join(__dirname, 'reports');
  
  if (!fs.existsSync(dataDir)) {
    fs.mkdirSync(dataDir, { recursive: true });
    console.log('📁 Dossier data créé');
  }
  
  if (!fs.existsSync(uploadsDir)) {
    fs.mkdirSync(uploadsDir, { recursive: true });
    console.log('📁 Dossier uploads créé');
  }
  
  if (!fs.existsSync(reportsDir)) {
    fs.mkdirSync(reportsDir, { recursive: true });
    console.log('📁 Dossier reports créé');
  }
});

module.exports = app;


