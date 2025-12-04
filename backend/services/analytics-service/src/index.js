const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const config = require('../../config/environment');
const { errorHandler, asyncHandler, AppError } = require('../../middleware/errorHandler');

const analyticsRoutes = require('./routes/analyticsRoutes');

const app = express();
const PORT = config.services.analytics.port;

// Middleware
app.use(cors({
  origin: config.cors.origin,
  credentials: true,
}));
app.use(express.json());

// Routes
app.use('/api/analytics', analyticsRoutes);

// Health check
app.get('/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    service: 'analytics-service',
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
    console.log('✅ Analytics Service: Connected to MongoDB');
    app.listen(PORT, () => {
      console.log(`🚀 Analytics Service running on port ${PORT}`);
      console.log(`🔗 MongoDB: ${config.mongodb.uri}`);
    });
  })
  .catch(err => {
    console.error('❌ Analytics Service: MongoDB connection error:', err.message);
    process.exit(1);
  });