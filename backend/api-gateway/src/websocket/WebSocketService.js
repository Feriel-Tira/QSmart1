/**
 * Service WebSocket pour les updates real-time
 * Gère les connexions Socket.io et les événements en temps réel
 */

const socketIO = require('socket.io');

class WebSocketService {
  constructor(server) {
    this.io = socketIO(server, {
      cors: {
        origin: process.env.CORS_ORIGIN || 'http://localhost:*',
        methods: ['GET', 'POST'],
        credentials: true,
      },
    });

    // Stocker les connexions actives
    this.userConnections = new Map(); // userId -> socketId
    this.queueConnections = new Map(); // queueId -> Set of socketIds

    this.setupEventHandlers();
  }

  /**
   * Configure les handlers d'événements Socket.io
   */
  setupEventHandlers() {
    this.io.on('connection', (socket) => {
      console.log(`\n📱 Nouvelle connexion WebSocket: ${socket.id}`);

      // Utilisateur se connecte à une queue
      socket.on('join-queue', (data) => {
        const { userId, queueId } = data;
        if (!userId || !queueId) {
          socket.emit('error', { message: 'userId et queueId requis' });
          return;
        }

        socket.join(`queue-${queueId}`);
        socket.join(`user-${userId}`);

        this.userConnections.set(userId, socket.id);

        if (!this.queueConnections.has(queueId)) {
          this.queueConnections.set(queueId, new Set());
        }
        this.queueConnections.get(queueId).add(socket.id);

        console.log(`✅ ${userId} rejoint la queue ${queueId}`);
        
        socket.emit('connected', { 
          message: 'Connecté à la queue',
          socketId: socket.id 
        });
      });

      // Utilisateur quitte une queue
      socket.on('leave-queue', (data) => {
        const { userId, queueId } = data;
        
        socket.leave(`queue-${queueId}`);
        socket.leave(`user-${userId}`);

        this.userConnections.delete(userId);
        if (this.queueConnections.has(queueId)) {
          this.queueConnections.get(queueId).delete(socket.id);
        }

        console.log(`❌ ${userId} quitte la queue ${queueId}`);
      });

      // Ping pour vérifier la connexion
      socket.on('ping', () => {
        socket.emit('pong');
      });

      // Déconnexion
      socket.on('disconnect', () => {
        // Nettoyer les connexions
        for (const [userId, socketId] of this.userConnections.entries()) {
          if (socketId === socket.id) {
            this.userConnections.delete(userId);
          }
        }

        for (const queues of this.queueConnections.values()) {
          queues.delete(socket.id);
        }

        console.log(`🔌 Déconnexion WebSocket: ${socket.id}`);
      });

      // Gestion des erreurs
      socket.on('error', (error) => {
        console.error(`❌ Erreur Socket: ${error}`);
      });
    });
  }

  /**
   * Notifie tous les utilisateurs d'une queue que le ticket est appelé
   */
  notifyTicketCalled(queueId, ticketData) {
    this.io.to(`queue-${queueId}`).emit('ticket-called', {
      ticketNumber: ticketData.ticketNumber,
      ticketId: ticketData.ticketId,
      position: ticketData.position,
      timestamp: new Date().toISOString(),
    });

    console.log(`📢 Ticket appelé: ${ticketData.ticketNumber} dans queue ${queueId}`);
  }

  /**
   * Notifie un utilisateur spécifique que son ticket est appelé
   */
  notifyUserTicketCalled(userId, ticketData) {
    this.io.to(`user-${userId}`).emit('your-ticket-called', {
      ticketNumber: ticketData.ticketNumber,
      ticketId: ticketData.ticketId,
      message: `Votre ticket ${ticketData.ticketNumber} est appelé! Présentez-vous au guichet.`,
      timestamp: new Date().toISOString(),
    });

    console.log(`📢 Notification personnelle: ${ticketData.ticketNumber} pour user ${userId}`);
  }

  /**
   * Update la position dans la queue pour tous les utilisateurs
   */
  updateQueuePosition(queueId, positions) {
    this.io.to(`queue-${queueId}`).emit('queue-position-update', {
      positions, // Array de {ticketId, position}
      timestamp: new Date().toISOString(),
    });

    console.log(`📍 Update positions dans queue ${queueId}`);
  }

  /**
   * Notifie l'état de la queue
   */
  updateQueueStatus(queueId, status) {
    this.io.to(`queue-${queueId}`).emit('queue-status-update', {
      queueId,
      status, // {totalWaiting, averageWaitTime, isActive}
      timestamp: new Date().toISOString(),
    });

    console.log(`📊 Update status queue ${queueId}`);
  }

  /**
   * Notifie une nouvelle notification
   */
  sendNotification(userId, notification) {
    this.io.to(`user-${userId}`).emit('notification', {
      type: notification.type,
      title: notification.title,
      message: notification.message,
      timestamp: new Date().toISOString(),
    });

    console.log(`🔔 Notification envoyée à ${userId}`);
  }

  /**
   * Broadcast un événement à tous les clients connectés
   */
  broadcast(eventName, data) {
    this.io.emit(eventName, {
      ...data,
      timestamp: new Date().toISOString(),
    });
  }

  /**
   * Récupère le nombre de clients connectés
   */
  getConnectedUsersCount() {
    return this.userConnections.size;
  }

  /**
   * Récupère les clients connectés pour une queue
   */
  getQueueConnectedCount(queueId) {
    return this.queueConnections.get(queueId)?.size || 0;
  }
}

module.exports = WebSocketService;
