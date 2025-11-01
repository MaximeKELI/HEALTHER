const { GoogleGenerativeAI } = require('@google/generative-ai');

class GeminiService {
  constructor() {
    this.apiKey = process.env.GEMINI_API_KEY || '';
    this.modelName = process.env.GEMINI_MODEL || 'models/gemini-2.5-flash';
    this.genAI = null;
    this.model = null;
    
    if (this.apiKey) {
      try {
        this.genAI = new GoogleGenerativeAI(this.apiKey);
        this.model = this.genAI.getGenerativeModel({ model: this.modelName });
      } catch (error) {
        console.error('Erreur initialisation Gemini:', error);
      }
    } else {
      console.warn('⚠️  GEMINI_API_KEY non configurée. Le chatbot IA ne sera pas disponible.');
    }
  }

  /**
   * Vérifier si le service est disponible
   */
  isAvailable() {
    return this.apiKey && this.model !== null;
  }

  /**
   * Générer une réponse du chatbot
   * @param {string} message - Message de l'utilisateur
   * @param {Array} conversationHistory - Historique de la conversation
   * @param {Object} context - Contexte utilisateur (rôle, région, etc.)
   * @returns {Promise<string>} - Réponse du chatbot
   */
  async generateResponse(message, conversationHistory = [], context = {}) {
    if (!this.isAvailable()) {
      throw new Error('Service Gemini non disponible. Vérifiez la configuration de GEMINI_API_KEY.');
    }

    try {
      // Construire le prompt avec contexte
      const systemPrompt = this._buildSystemPrompt(context);
      
      // Construire l'historique de conversation
      const chatHistory = this._buildChatHistory(conversationHistory);
      
      // Construire le prompt complet
      const fullPrompt = `${systemPrompt}\n\n${chatHistory}\n\nUtilisateur: ${message}\nAssistant:`;

      // Générer la réponse
      const result = await this.model.generateContent(fullPrompt);
      const response = await result.response;
      const text = response.text();

      if (!text || text.trim().length === 0) {
        throw new Error('Réponse vide de Gemini');
      }

      return text.trim();
    } catch (error) {
      console.error('Erreur génération réponse Gemini:', error);
      throw new Error('Erreur lors de la génération de la réponse. Veuillez réessayer.');
    }
  }

  /**
   * Construire le prompt système avec contexte
   */
  _buildSystemPrompt(context) {
    let prompt = `Tu es un assistant IA spécialisé dans la santé publique et le diagnostic médical pour HEALTHER.
Tu aides les agents de santé, superviseurs, épidémiologistes et administrateurs dans leur travail quotidien.

Contexte utilisateur:
- Rôle: ${context.role || 'agent'}
${context.region ? `- Région: ${context.region}` : ''}
${context.centreSante ? `- Centre de santé: ${context.centreSante}` : ''}

Instructions:
1. Réponds de manière claire, concise et professionnelle
2. Fournis des informations médicales précises et à jour
3. Pour les diagnostics, oriente vers la consultation d'un professionnel de santé
4. Aide avec les fonctionnalités de la plateforme HEALTHER
5. Sois respectueux et empathique
6. Si tu ne sais pas quelque chose, dis-le clairement

Tu dois répondre en français sauf demande contraire.`;

    return prompt;
  }

  /**
   * Construire l'historique de conversation
   */
  _buildChatHistory(conversationHistory) {
    if (!conversationHistory || conversationHistory.length === 0) {
      return '';
    }

    // Prendre les 10 derniers messages pour éviter de dépasser les limites
    const recentHistory = conversationHistory.slice(-10);
    
    return recentHistory.map(msg => {
      const role = msg.role || (msg.from === 'user' ? 'Utilisateur' : 'Assistant');
      return `${role}: ${msg.message || msg.content || ''}`;
    }).join('\n');
  }

  /**
   * Générer une réponse en streaming (pour future amélioration)
   */
  async *streamResponse(message, conversationHistory = [], context = {}) {
    if (!this.isAvailable()) {
      throw new Error('Service Gemini non disponible.');
    }

    try {
      const systemPrompt = this._buildSystemPrompt(context);
      const chatHistory = this._buildChatHistory(conversationHistory);
      const fullPrompt = `${systemPrompt}\n\n${chatHistory}\n\nUtilisateur: ${message}\nAssistant:`;

      // Note: L'API Gemini streaming nécessite une configuration différente
      // Pour l'instant, on retourne la réponse complète
      const response = await this.generateResponse(message, conversationHistory, context);
      
      // Simuler le streaming en mots
      const words = response.split(' ');
      for (const word of words) {
        yield word + ' ';
        // Petit délai pour simuler le streaming
        await new Promise(resolve => setTimeout(resolve, 50));
      }
    } catch (error) {
      console.error('Erreur streaming Gemini:', error);
      throw error;
    }
  }
}

module.exports = new GeminiService();

