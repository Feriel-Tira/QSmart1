const { asyncHandler, AppError } = require('../../middleware/errorHandler');
const notificationService = require('../services/notificationService');

/**
 * Crée et envoie une notification
 */
exports.createNotification = asyncHandler(async (req, res) => {
  const { type, userId, userEmail, userPhone, title, message, metadata, channels } = req.body;

  if (!type || !title || !message) {
    throw new AppError('type, title et message sont requis', 400);
  }

  const notification = await notificationService.send({
    type,
    userId,
    userEmail,
    userPhone,
    title,
    message,
    metadata,
    channels: channels || { inApp: true, email: true },
  });

  res.status(201).json({
    success: true,
    message: 'Notification créée et envoyée',
    data: notification,
  });
});

/**
 * Récupère les notifications d'un utilisateur
 */
exports.getUserNotifications = asyncHandler(async (req, res) => {
  const { userId } = req.params;
  const { limit = 10 } = req.query;

  if (!userId) {
    throw new AppError('userId est requis', 400);
  }

  const notifications = await notificationService.getUserNotifications(userId, parseInt(limit));

  res.json({
    success: true,
    data: notifications,
  });
});

/**
 * Marque une notification comme livrée
 */
exports.markAsDelivered = asyncHandler(async (req, res) => {
  const { notificationId } = req.params;

  if (!notificationId) {
    throw new AppError('notificationId est requis', 400);
  }

  const notification = await notificationService.markAsDelivered(notificationId);

  if (!notification) {
    throw new AppError('Notification not found', 404);
  }

  res.json({
    success: true,
    message: 'Notification marquée comme livrée',
    data: notification,
  });
});

/**
 * Webhook pour les événements (crée automatiquement une notification)
 */
exports.queueCreated = asyncHandler(async (req, res) => {
  const { queueId, queueName } = req.body;

  if (!queueId || !queueName) {
    throw new AppError('queueId et queueName requis', 400);
  }

  const notification = await notificationService.send({
    type: 'QUEUE_CREATED',
    title: '📋 Nouvelle file d\'attente créée',
    message: `La file d'attente "${queueName}" est maintenant disponible.`,
    metadata: { queueId, queueName },
    channels: { inApp: true },
  });

  res.status(201).json({
    success: true,
    data: notification,
  });
});

/**
 * Webhook pour les tickets appelés
 */
exports.ticketCalled = asyncHandler(async (req, res) => {
  const { ticketId, ticketNumber, userId, userEmail, userPhone } = req.body;

  if (!ticketNumber || !userId) {
    throw new AppError('ticketNumber et userId requis', 400);
  }

  const notification = await notificationService.send({
    type: 'TICKET_CALLED',
    userId,
    userEmail,
    userPhone,
    title: '📢 Votre ticket est appelé!',
    message: `Le ticket ${ticketNumber} est en cours de traitement. Présentez-vous au guichet.`,
    metadata: { ticketId, ticketNumber },
    channels: { inApp: true, email: !!userEmail, sms: !!userPhone },
  });

  res.status(201).json({
    success: true,
    data: notification,
  });
});
