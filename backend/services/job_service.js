const { Queue, Worker } = require('bullmq');
const Redis = require('ioredis');

// Connexion Redis
const redisConnection = new Redis({
  host: process.env.REDIS_HOST || 'localhost',
  port: parseInt(process.env.REDIS_PORT || '6379', 10),
  password: process.env.REDIS_PASSWORD || undefined,
  maxRetriesPerRequest: null,
});

// Queues
const reportQueue = new Queue('reports', { connection: redisConnection });
const notificationQueue = new Queue('notifications', { connection: redisConnection });
const syncQueue = new Queue('sync', { connection: redisConnection });

/**
 * Ajouter un job de génération de rapport
 */
async function queueReportGeneration(reportId, userId, parameters) {
  await reportQueue.add('generate-report', {
    reportId,
    userId,
    parameters,
  }, {
    attempts: 3,
    backoff: {
      type: 'exponential',
      delay: 2000,
    },
  });
}

/**
 * Ajouter un job de notification
 */
async function queueNotification(userIds, type, title, message, metadata) {
  await notificationQueue.add('send-notification', {
    userIds,
    type,
    title,
    message,
    metadata,
  }, {
    attempts: 2,
    backoff: {
      type: 'fixed',
      delay: 1000,
    },
  });
}

/**
 * Ajouter un job de synchronisation offline
 */
async function queueSyncItem(queueItemId) {
  await syncQueue.add('sync-item', {
    queueItemId,
  }, {
    attempts: 5,
    backoff: {
      type: 'exponential',
      delay: 5000,
    },
  });
}

// Worker pour génération de rapports
const reportWorker = new Worker('reports', async (job) => {
  const { reportId, userId, parameters } = job.data;
  console.log(`📊 Génération rapport ${reportId} pour utilisateur ${userId}`);
  
  // TODO: Appeler service de génération de rapports
  const { generateReport } = require('../services/report_service');
  await generateReport(reportId, userId, parameters);
}, { connection: redisConnection });

// Worker pour notifications
const notificationWorker = new Worker('notifications', async (job) => {
  const { userIds, type, title, message, metadata } = job.data;
  console.log(`📢 Notification ${type} pour ${userIds.length} utilisateurs`);
  
  const notificationService = require('./notification_service');
  await notificationService.notifyUsers(userIds, type, title, message, metadata, null);
}, { connection: redisConnection });

// Worker pour synchronisation
const syncWorker = new Worker('sync', async (job) => {
  const { queueItemId } = job.data;
  console.log(`🔄 Sync item ${queueItemId}`);
  
  // TODO: Implémenter logique de sync
}, { connection: redisConnection });

module.exports = {
  queueReportGeneration,
  queueNotification,
  queueSyncItem,
};
