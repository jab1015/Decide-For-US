const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
require('dotenv').config();

const app = express();

// Import routes
const authRoutes = require('./routes/auth');
const suggestionRoutes = require('./routes/suggestions');
const venueRoutes = require('./routes/venues');
const subscriptionRoutes = require('./routes/subscriptions');
const premiumRoutes = require('./routes/premium');

// Middleware
app.use(cors());
app.use(morgan('dev'));

// Basic health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// IMPORTANT: Subscriptions route needs raw body for Stripe webhooks
// We handle express.json() inside the other routes or after the webhook
app.use('/api/subscribe', subscriptionRoutes);

// Global body parser for other routes
app.use(express.json());

// Use other routes
app.use('/api/auth', authRoutes);
app.use('/api/suggestions', suggestionRoutes);
app.use('/api/venues', venueRoutes);
app.use('/api', premiumRoutes);

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    error: 'Internal Server Error',
    message: err.message
  });
});

module.exports = app;
