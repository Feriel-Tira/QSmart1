/**
 * Configuration centralisée avec validation
 * Charge et valide les variables d'environnement
 */

require('dotenv').config();

// Déterminer si on est en mode Docker ou local
const isDocker = process.env.NODE_ENV === 'production' || process.env.DOCKER_COMPOSE === 'true';

const config = {
  // Environment
  env: process.env.NODE_ENV || 'development',
  isProduction: process.env.NODE_ENV === 'production',
  isDevelopment: process.env.NODE_ENV === 'development',
  isDocker: isDocker,

  // Database
  mongodb: {
    uri: isDocker 
      ? process.env.MONGODB_URI || 'mongodb://mongo:27017/smartqueue_db'
      : process.env.MONGODB_DEV_URI || 'mongodb://localhost:27017/smartqueue_db',
  },

  // API Gateway
  apiGateway: {
    port: process.env.API_GATEWAY_PORT || 4000,
  },

  // Services
  services: {
    queue: {
      port: process.env.QUEUE_SERVICE_PORT || 4001,
      url: isDocker 
        ? process.env.QUEUE_SERVICE_URL || 'http://queue-service:4001'
        : process.env.QUEUE_SERVICE_URL_LOCAL || 'http://localhost:4001',
    },
    ticket: {
      port: process.env.TICKET_SERVICE_PORT || 4002,
      url: isDocker 
        ? process.env.TICKET_SERVICE_URL || 'http://ticket-service:4002'
        : process.env.TICKET_SERVICE_URL_LOCAL || 'http://localhost:4002',
    },
    user: {
      port: process.env.USER_SERVICE_PORT || 4003,
      url: isDocker 
        ? process.env.USER_SERVICE_URL || 'http://user-service:4003'
        : process.env.USER_SERVICE_URL_LOCAL || 'http://localhost:4003',
    },
    analytics: {
      port: process.env.ANALYTICS_SERVICE_PORT || 4004,
      url: isDocker 
        ? process.env.ANALYTICS_SERVICE_URL || 'http://analytics-service:4004'
        : process.env.ANALYTICS_SERVICE_URL_LOCAL || 'http://localhost:4004',
    },
    notification: {
      port: process.env.NOTIFICATION_SERVICE_PORT || 4005,
      url: isDocker 
        ? process.env.NOTIFICATION_SERVICE_URL || 'http://notification-service:4005'
        : process.env.NOTIFICATION_SERVICE_URL_LOCAL || 'http://localhost:4005',
    },
  },

  // Security
  jwt: {
    secret: process.env.JWT_SECRET || 'your_super_secret_key_change_in_production',
    expiry: process.env.JWT_EXPIRY || '24h',
  },

  // CORS
  cors: {
    origin: process.env.CORS_ORIGIN || 'http://localhost:*',
  },

  // Logging
  logging: {
    level: process.env.LOG_LEVEL || 'debug',
  },

  // Notification
  notification: {
    email: {
      enabled: process.env.NOTIFICATION_EMAIL_ENABLED === 'true',
      from: process.env.NOTIFICATION_EMAIL_FROM || 'noreply@smartqueue.com',
    },
    sms: {
      enabled: process.env.NOTIFICATION_SMS_ENABLED === 'true',
    },
  },

  // Redis (optionnel)
  redis: {
    enabled: process.env.REDIS_ENABLED === 'true',
    url: process.env.REDIS_URL || 'redis://localhost:6379',
  },
};

/**
 * Valide que toutes les variables requises sont présentes
 */
function validateConfig() {
  const required = [
    'JWT_SECRET',
    'MONGODB_URI',
  ];

  const missing = required.filter(key => !process.env[key]);

  if (missing.length > 0) {
    console.warn(`⚠️  Variables d'environnement manquantes: ${missing.join(', ')}`);
    console.warn('✅ Valeurs par défaut utilisées');
  }

  // Validation du JWT_SECRET en production
  if (config.isProduction && process.env.JWT_SECRET === 'your_super_secret_key_change_in_production') {
    throw new Error('❌ ERREUR CRITIQUE: JWT_SECRET doit être changé en production!');
  }

  console.log(`✅ Configuration chargée - Env: ${config.env}, Docker: ${config.isDocker}`);
}

// Valider au démarrage
validateConfig();

module.exports = config;
