const express = require('express');
const notificationController = require('../controllers/notificationController');

const router = express.Router();

// Créer et envoyer une notification
router.post('/', notificationController.createNotification);

// Récupérer les notifications d'un utilisateur
router.get('/user/:userId', notificationController.getUserNotifications);

// Marquer comme livrée
router.put('/:notificationId/delivered', notificationController.markAsDelivered);

// Webhooks pour les événements
router.post('/queue-created', notificationController.queueCreated);
router.post('/ticket-called', notificationController.ticketCalled);

module.exports = router;
