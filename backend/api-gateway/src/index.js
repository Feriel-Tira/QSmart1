// SMARTQUEUE API GATEWAY
const express = require('express');
const http = require('http');
const { ApolloServer } = require('apollo-server-express');
const cors = require('cors');
const config = require('../../config/environment');
const { errorHandler, asyncHandler } = require('../../middleware/errorHandler');
const WebSocketService = require('./websocket/WebSocketService');

const app = express();
const server = http.createServer(app);
const PORT = config.apiGateway.port;

console.log('=== SMARTQUEUE API GATEWAY DÉMARRAGE ===');

// Initialiser WebSocket
const wsService = new WebSocketService(server);
app.locals.wsService = wsService;

// Schéma GraphQL en string (pas besoin de gql)
const typeDefs = `
  type Query {
    hello: String
    health: Health
    queues: [Queue]
    tickets: [Ticket]
  }
  
  type Health {
    status: String!
    timestamp: String!
    service: String!
  }
  
  type Queue {
    id: ID!
    name: String!
    isActive: Boolean!
    description: String
  }
  
  type Ticket {
    id: ID!
    ticketNumber: String!
    status: String!
    position: Int
  }
`;

// Résolveurs simples
const resolvers = {
  Query: {
    hello: () => 'Bienvenue sur SmartQueue!',
    health: () => ({
      status: 'OK',
      timestamp: new Date().toISOString(),
      service: 'api-gateway'
    }),
    queues: () => [
      { id: '1', name: 'Pharmacie Centrale', isActive: true, description: 'Service pharmacie' },
      { id: '2', name: 'Banque Nationale', isActive: true, description: 'Guichet bancaire' },
      { id: '3', name: 'Hôpital Ville', isActive: true, description: 'Urgences médicales' }
    ],
    tickets: () => [
      { id: '1', ticketNumber: 'PHA-001', status: 'WAITING', position: 1 },
      { id: '2', ticketNumber: 'PHA-002', status: 'CALLED', position: 2 },
      { id: '3', ticketNumber: 'BNQ-001', status: 'WAITING', position: 1 }
    ]
  }
};

async function startServer() {
  console.log('Initialisation du serveur...');
  
  // Middleware
  app.use(cors({
    origin: config.cors.origin,
    credentials: true,
  }));
  app.use(express.json());
  
  // Créer Apollo Server (v3)
  const apolloServer = new ApolloServer({
    typeDefs,
    resolvers,
    introspection: true
  });
  
  await apolloServer.start();
  
  // Appliquer middleware Apollo à Express
  apolloServer.applyMiddleware({ app, path: '/graphql' });
  
  // Routes REST
  app.get('/health', (req, res) => {
    res.json({
      status: 'OK',
      service: 'smartqueue-api-gateway',
      version: '1.0.0',
      environment: config.env,
      timestamp: new Date().toISOString(),
      message: '✅ API Gateway opérationnelle'
    });
  });
  
  app.get('/', (req, res) => {
    res.json({
      name: 'SmartQueue API Gateway',
      description: 'Système de gestion intelligente des files d\'attente',
      version: '1.0.0',
      environment: config.env,
      endpoints: {
        graphql: '/graphql',
        health: '/health',
        'ws-stats': '/ws-stats',
      }
    });
  });

  // Endpoint interne pour émettre des événements WebSocket
  app.post('/emit-event', asyncHandler(async (req, res) => {
    const { event, ...data } = req.body;

    if (!event) {
      throw new Error('event requis');
    }

    // Émettre l'événement via WebSocket
    switch (event) {
      case 'ticket-called':
        wsService.notifyTicketCalled(data.queueId, data.ticketData);
        break;
      case 'queue-position-update':
        wsService.updateQueuePosition(data.queueId, data.positions);
        break;
      case 'queue-status-update':
        wsService.updateQueueStatus(data.queueId, data.status);
        break;
      default:
        wsService.broadcast(event, data);
    }

    res.json({ success: true, message: `Événement ${event} émis` });
  }));

  // Endpoint pour les stats WebSocket
  app.get('/ws-stats', (req, res) => {
    res.json({
      connectedUsers: wsService.getConnectedUsersCount(),
      timestamp: new Date().toISOString(),
    });
  });

  // Middleware d'erreur global (doit être en dernier)
  app.use(errorHandler);
  
  // Démarrer
  server.listen(PORT, () => {
    console.log(`\n🚀 API Gateway prêt sur port ${PORT}`);
    console.log(`📊 GraphQL: http://localhost:${PORT}/graphql`);
    console.log(`🏥 Health: http://localhost:${PORT}/health`);
    console.log(`🔌 WebSocket: ws://localhost:${PORT}`);
    console.log(`🔒 JWT Secret configuré: ${config.jwt.secret.substring(0, 10)}...`);
    console.log(`🗄️  MongoDB: ${config.mongodb.uri}\n`);
  });
}

// Démarrer
startServer().catch(error => {
  console.error('❌ Erreur au démarrage:', error);
  process.exit(1);
});