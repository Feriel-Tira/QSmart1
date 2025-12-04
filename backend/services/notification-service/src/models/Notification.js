const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema({
  // Type de notification
  type: {
    type: String,
    enum: ['TICKET_CALLED', 'QUEUE_CREATED', 'STATUS_UPDATE', 'GENERAL'],
    required: true,
  },

  // Destinataire
  userId: String,
  userEmail: String,
  userPhone: String,

  // Contenu
  title: {
    type: String,
    required: true,
  },
  message: {
    type: String,
    required: true,
  },
  metadata: {
    queueId: String,
    queueName: String,
    ticketId: String,
    ticketNumber: String,
  },

  // Canaux d'envoi
  channels: {
    email: { type: Boolean, default: false },
    sms: { type: Boolean, default: false },
    push: { type: Boolean, default: false },
    inApp: { type: Boolean, default: true },
  },

  // Statuts
  status: {
    type: String,
    enum: ['PENDING', 'SENT', 'FAILED', 'DELIVERED'],
    default: 'PENDING',
  },
  sentAt: Date,
  deliveredAt: Date,
  error: String,

  // Timestamps
  createdAt: {
    type: Date,
    default: Date.now,
  },
});

module.exports = mongoose.model('Notification', notificationSchema);
