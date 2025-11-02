# Dockerfile pour HEALTHER Backend
FROM node:18-alpine

# Définir le répertoire de travail
WORKDIR /app

# Copier les fichiers package
COPY backend/package*.json ./

# Installer les dépendances
RUN npm ci --only=production

# Copier le code de l'application
COPY backend/ ./

# Créer les dossiers nécessaires
RUN mkdir -p data uploads reports

# Exposer le port
EXPOSE 3000

# Variables d'environnement par défaut
ENV NODE_ENV=production
ENV PORT=3000

# Commande de démarrage
CMD ["node", "server.js"]

