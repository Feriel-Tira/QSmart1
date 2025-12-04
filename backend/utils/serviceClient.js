/**
 * Utilitaire pour les appels HTTP entre services
 * Centralise les URLs et la gestion d'erreurs
 */

const axios = require('axios');
const config = require('../config/environment');
const { AppError } = require('./errorHandler');

/**
 * Client HTTP pour les appels inter-services
 */
class ServiceClient {
  constructor() {
    this.client = axios.create({
      timeout: 5000, // 5 secondes timeout
    });
  }

  /**
   * Effectue une requête GET vers un service
   */
  async get(serviceName, endpoint) {
    try {
      const url = `${this._getServiceUrl(serviceName)}${endpoint}`;
      console.log(`📤 GET ${serviceName}${endpoint}`);
      const response = await this.client.get(url);
      return response.data;
    } catch (error) {
      this._handleError(serviceName, error);
    }
  }

  /**
   * Effectue une requête POST vers un service
   */
  async post(serviceName, endpoint, data) {
    try {
      const url = `${this._getServiceUrl(serviceName)}${endpoint}`;
      console.log(`📤 POST ${serviceName}${endpoint}`);
      const response = await this.client.post(url, data);
      return response.data;
    } catch (error) {
      this._handleError(serviceName, error);
    }
  }

  /**
   * Effectue une requête PUT vers un service
   */
  async put(serviceName, endpoint, data) {
    try {
      const url = `${this._getServiceUrl(serviceName)}${endpoint}`;
      console.log(`📤 PUT ${serviceName}${endpoint}`);
      const response = await this.client.put(url, data);
      return response.data;
    } catch (error) {
      this._handleError(serviceName, error);
    }
  }

  /**
   * Effectue une requête DELETE vers un service
   */
  async delete(serviceName, endpoint) {
    try {
      const url = `${this._getServiceUrl(serviceName)}${endpoint}`;
      console.log(`📤 DELETE ${serviceName}${endpoint}`);
      const response = await this.client.delete(url);
      return response.data;
    } catch (error) {
      this._handleError(serviceName, error);
    }
  }

  /**
   * Récupère l'URL de base d'un service
   */
  _getServiceUrl(serviceName) {
    const urls = {
      queue: config.services.queue.url,
      ticket: config.services.ticket.url,
      user: config.services.user.url,
      analytics: config.services.analytics.url,
      notification: config.services.notification.url,
    };

    if (!urls[serviceName]) {
      throw new AppError(`Service "${serviceName}" non trouvé`, 400);
    }

    return urls[serviceName];
  }

  /**
   * Gère les erreurs des appels inter-services
   */
  _handleError(serviceName, error) {
    console.error(`❌ Erreur ${serviceName}:`, error.message);

    if (error.response) {
      // Erreur HTTP
      throw new AppError(
        `${serviceName}: ${error.response.data?.error?.message || error.message}`,
        error.response.status
      );
    } else if (error.code === 'ECONNREFUSED') {
      throw new AppError(
        `Service ${serviceName} indisponible (connexion refusée)`,
        503
      );
    } else if (error.code === 'ECONNABORTED') {
      throw new AppError(
        `Timeout: Service ${serviceName} n'a pas répondu`,
        504
      );
    } else {
      throw new AppError(
        `Erreur réseau: ${error.message}`,
        500
      );
    }
  }
}

// Exporter une instance singleton
module.exports = new ServiceClient();
