/**
 * Helper pour utiliser WebSocket dans les contrôleurs des services
 * via des appels HTTP au gateway
 */

const axios = require('axios');
const config = require('../../config/environment');

class WebSocketEventEmitter {
  /**
   * Notifie que un ticket a été appelé
   */
  static async ticketCalled(queueId, ticketData) {
    try {
      await axios.post(
        `${config.services.notification.url}/api/notifications/ticket-called`,
        {
          ticketId: ticketData.ticketId,
          ticketNumber: ticketData.ticketNumber,
          userId: ticketData.userId,
          userEmail: ticketData.userEmail,
          userPhone: ticketData.userPhone,
        },
        { timeout: 3000 }
      );

      // Appeler l'endpoint du gateway pour émettre l'événement WebSocket
      await axios.post(
        `http://api-gateway:4000/emit-event`,
        {
          event: 'ticket-called',
          queueId,
          ticketData,
        },
        { timeout: 3000 }
      ).catch(() => {
        // Ignorer l'erreur si le gateway n'est pas accessible
        console.warn('⚠️  Gateway not reachable for WebSocket event');
      });

    } catch (error) {
      console.error('❌ Erreur ticketCalled:', error.message);
    }
  }

  /**
   * Update la position dans la queue
   */
  static async updateQueuePosition(queueId, positions) {
    try {
      await axios.post(
        `http://api-gateway:4000/emit-event`,
        {
          event: 'queue-position-update',
          queueId,
          positions,
        },
        { timeout: 3000 }
      ).catch(() => {
        console.warn('⚠️  Gateway not reachable for WebSocket event');
      });
    } catch (error) {
      console.error('❌ Erreur updateQueuePosition:', error.message);
    }
  }

  /**
   * Update le statut de la queue
   */
  static async updateQueueStatus(queueId, status) {
    try {
      await axios.post(
        `http://api-gateway:4000/emit-event`,
        {
          event: 'queue-status-update',
          queueId,
          status,
        },
        { timeout: 3000 }
      ).catch(() => {
        console.warn('⚠️  Gateway not reachable for WebSocket event');
      });
    } catch (error) {
      console.error('❌ Erreur updateQueueStatus:', error.message);
    }
  }
}

module.exports = WebSocketEventEmitter;
