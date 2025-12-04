/**
 * Service d'envoi de notifications
 */

const nodemailer = require('nodemailer');
const config = require('../../../config/environment');
const Notification = require('../models/Notification');

class NotificationService {
  constructor() {
    this.emailTransporter = null;
    this.initEmailTransporter();
  }

  /**
   * Initialise le transporteur d'emails
   */
  initEmailTransporter() {
    // Configuration simple - à remplacer par un vrai SMTP en production
    this.emailTransporter = nodemailer.createTransport({
      service: process.env.EMAIL_SERVICE || 'gmail',
      auth: {
        user: process.env.EMAIL_USER || 'your-email@gmail.com',
        pass: process.env.EMAIL_PASSWORD || 'your-app-password',
      },
    });
  }

  /**
   * Envoie une notification
   */
  async send(notificationData) {
    try {
      const notification = new Notification({
        ...notificationData,
        status: 'PENDING',
      });

      await notification.save();

      // Envoyer via les canaux activés
      const promises = [];

      if (notificationData.channels?.email && notificationData.userEmail) {
        promises.push(this.sendEmail(notification));
      }

      if (notificationData.channels?.sms && notificationData.userPhone) {
        promises.push(this.sendSMS(notification));
      }

      if (notificationData.channels?.push) {
        promises.push(this.sendPushNotification(notification));
      }

      // Exécuter les envois en parallèle
      const results = await Promise.allSettled(promises);

      // Mettre à jour le statut
      if (results.some(r => r.status === 'fulfilled')) {
        notification.status = 'SENT';
        notification.sentAt = new Date();
      } else {
        notification.status = 'FAILED';
        notification.error = 'Tous les canaux ont échoué';
      }

      await notification.save();

      console.log(`📧 Notification envoyée: ${notification._id}`);
      return notification;

    } catch (error) {
      console.error('❌ Erreur envoi notification:', error.message);
      throw error;
    }
  }

  /**
   * Envoie une notification par email
   */
  async sendEmail(notification) {
    try {
      if (!config.notification.email.enabled) {
        console.log('⚠️  Email notifications désactivées');
        return false;
      }

      // En développement, simplement logger
      if (config.env === 'development') {
        console.log(`📧 EMAIL - À: ${notification.userEmail}`);
        console.log(`   Sujet: ${notification.title}`);
        console.log(`   Message: ${notification.message}`);
        return true;
      }

      // En production, envoyer réellement
      await this.emailTransporter.sendMail({
        from: config.notification.email.from,
        to: notification.userEmail,
        subject: notification.title,
        html: `
          <h2>${notification.title}</h2>
          <p>${notification.message}</p>
          ${notification.metadata?.queueName ? `<p><strong>File:</strong> ${notification.metadata.queueName}</p>` : ''}
          ${notification.metadata?.ticketNumber ? `<p><strong>Ticket:</strong> ${notification.metadata.ticketNumber}</p>` : ''}
        `,
      });

      return true;
    } catch (error) {
      console.error('❌ Erreur email:', error.message);
      return false;
    }
  }

  /**
   * Envoie une notification SMS (simulée)
   */
  async sendSMS(notification) {
    try {
      if (!config.notification.sms.enabled) {
        console.log('⚠️  SMS notifications désactivées');
        return false;
      }

      // Simuler l'envoi SMS
      console.log(`📱 SMS - À: ${notification.userPhone}`);
      console.log(`   Message: ${notification.message}`);
      return true;
    } catch (error) {
      console.error('❌ Erreur SMS:', error.message);
      return false;
    }
  }

  /**
   * Envoie une notification push (simulée)
   */
  async sendPushNotification(notification) {
    try {
      console.log(`🔔 PUSH - Titre: ${notification.title}`);
      console.log(`   Message: ${notification.message}`);
      return true;
    } catch (error) {
      console.error('❌ Erreur push:', error.message);
      return false;
    }
  }

  /**
   * Récupère l'historique des notifications d'un utilisateur
   */
  async getUserNotifications(userId, limit = 10) {
    return Notification.find({ userId })
      .sort({ createdAt: -1 })
      .limit(limit);
  }

  /**
   * Marque une notification comme lue
   */
  async markAsDelivered(notificationId) {
    return Notification.findByIdAndUpdate(
      notificationId,
      { 
        status: 'DELIVERED',
        deliveredAt: new Date(),
      },
      { new: true }
    );
  }
}

module.exports = new NotificationService();
