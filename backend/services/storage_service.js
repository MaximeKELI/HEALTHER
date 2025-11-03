const { S3Client, PutObjectCommand, GetObjectCommand } = require('@aws-sdk/client-s3');
const { getSignedUrl } = require('@aws-sdk/s3-request-presigner');
const MinIO = require('minio');
const crypto = require('crypto');
const path = require('path');

class StorageService {
  constructor() {
    this.provider = process.env.STORAGE_PROVIDER || 'local'; // 'local', 's3', 'minio'
    this.bucket = process.env.S3_BUCKET || 'made-diagnostics';
    
    // AWS S3
    if (this.provider === 's3') {
      if (!process.env.AWS_REGION || !process.env.AWS_ACCESS_KEY_ID || !process.env.AWS_SECRET_ACCESS_KEY) {
        console.warn('⚠️  AWS S3 configuré mais credentials manquantes. Utilisation du stockage local.');
        this.provider = 'local';
      } else {
        this.s3Client = new S3Client({
          region: process.env.AWS_REGION,
          credentials: {
            accessKeyId: process.env.AWS_ACCESS_KEY_ID,
            secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
          },
        });
      }
    }
    
    // MinIO
    if (this.provider === 'minio') {
      if (!process.env.MINIO_ENDPOINT || !process.env.MINIO_ACCESS_KEY || !process.env.MINIO_SECRET_KEY) {
        console.warn('⚠️  MinIO configuré mais credentials manquantes. Utilisation du stockage local.');
        this.provider = 'local';
      } else {
        this.minioClient = new MinIO.Client({
          endPoint: process.env.MINIO_ENDPOINT.replace(/^https?:\/\//, '').split(':')[0],
          port: parseInt(process.env.MINIO_PORT || '9000', 10),
          useSSL: process.env.MINIO_USE_SSL === 'true',
          accessKey: process.env.MINIO_ACCESS_KEY,
          secretKey: process.env.MINIO_SECRET_KEY,
        });
        
        // Créer le bucket s'il n'existe pas
        this.minioClient.bucketExists(this.bucket).then(exists => {
          if (!exists) {
            return this.minioClient.makeBucket(this.bucket, process.env.MINIO_REGION || 'us-east-1');
          }
        }).catch(err => console.error('Erreur MinIO bucket:', err));
      }
    }
  }

  /**
   * Upload un fichier
   * @param {Buffer} buffer - Contenu du fichier
   * @param {string} filename - Nom du fichier
   * @param {string} mimetype - Type MIME
   * @param {string} folder - Dossier de stockage (optionnel: 'diagnostics', 'profiles', etc.)
   * @returns {Promise<string>} - Chemin ou clé S3
   */
  async uploadFile(buffer, filename, mimetype, folder = 'diagnostics') {
    const uniqueId = crypto.randomBytes(16).toString('hex');
    const ext = path.extname(filename) || '.jpg';
    const key = `${folder}/${new Date().toISOString().split('T')[0]}/${uniqueId}${ext}`;
    
    if (this.provider === 's3') {
      const command = new PutObjectCommand({
        Bucket: this.bucket,
        Key: key,
        Body: buffer,
        ContentType: mimetype,
        CacheControl: 'max-age=31536000',
      });
      
      await this.s3Client.send(command);
      return key;
    }
    
    if (this.provider === 'minio') {
      await this.minioClient.putObject(this.bucket, key, buffer, buffer.length, {
        'Content-Type': mimetype,
        'Cache-Control': 'max-age=31536000',
      });
      return key;
    }
    
    // Local storage (fallback)
    const fs = require('fs');
    const uploadsDir = path.join(__dirname, '..', 'uploads');
    if (!fs.existsSync(uploadsDir)) {
      fs.mkdirSync(uploadsDir, { recursive: true });
    }
    
    const localPath = path.join(uploadsDir, `${uniqueId}${ext}`);
    fs.writeFileSync(localPath, buffer);
    return `uploads/${uniqueId}${ext}`;
  }

  /**
   * Obtenir une URL signée pour lire un fichier
   * @param {string} key - Clé S3 ou chemin local
   * @param {number} expiresIn - Durée de validité en secondes (défaut: 1h)
   * @returns {Promise<string>} - URL signée
   */
  async getSignedUrl(key, expiresIn = 3600) {
    if (this.provider === 's3') {
      const command = new GetObjectCommand({
        Bucket: this.bucket,
        Key: key,
      });
      return await getSignedUrl(this.s3Client, command, { expiresIn });
    }
    
    if (this.provider === 'minio') {
      return await this.minioClient.presignedGetObject(this.bucket, key, expiresIn);
    }
    
    // Local: retourner URL absolue côté API (sans /api)
    let baseUrl = process.env.API_BASE_URL || 'http://localhost:3000';
    // Si API_BASE_URL contient un suffixe /api, le retirer pour servir les fichiers statiques
    if (baseUrl.endsWith('/api')) {
      baseUrl = baseUrl.slice(0, -4);
    }
    return `${baseUrl}/${key}`;
  }

  /**
   * Supprimer un fichier
   * @param {string} key - Clé S3 ou chemin local
   */
  async deleteFile(key) {
    if (this.provider === 's3') {
      const { DeleteObjectCommand } = require('@aws-sdk/client-s3');
      await this.s3Client.send(new DeleteObjectCommand({
        Bucket: this.bucket,
        Key: key,
      }));
      return;
    }
    
    if (this.provider === 'minio') {
      await this.minioClient.removeObject(this.bucket, key);
      return;
    }
    
    // Local
    const fs = require('fs');
    const filePath = path.join(__dirname, '..', key);
    if (fs.existsSync(filePath)) {
      fs.unlinkSync(filePath);
    }
  }
}

module.exports = new StorageService();
