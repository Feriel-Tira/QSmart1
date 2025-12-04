const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const config = require('../../config/environment');
const { errorHandler, asyncHandler, AppError } = require('../../middleware/errorHandler');

const notificationRoutes = require('./routes/notificationRoutes');

const app = express();
const PORT = config.services.notification.port;

// Middleware
app.use(cors({
  origin: config.cors.origin,
  credentials: true,
}));
app.use(express.json());

// Routes
app.use('/api/notifications', notificationRoutes);

// Health check
app.get('/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    service: 'notification-service',
    environment: config.env,
    timestamp: new Date().toISOString(),
    mongodb: '✅ Connected'
  });
});

// Middleware d'erreur global (doit être en dernier)
app.use(errorHandler);

// Connect to MongoDB
mongoose.connect(config.mongodb.uri)
  .then(() => {
    console.log('✅ Notification Service: Connected to MongoDB');
    app.listen(PORT, () => {
      console.log(`🚀 Notification Service running on port ${PORT}`);
      console.log(`🔗 MongoDB: ${config.mongodb.uri}`);
    });
  })
  .catch(err => {
    console.error('❌ Notification Service: MongoDB connection error:', err.message);
    process.exit(1);
  });
