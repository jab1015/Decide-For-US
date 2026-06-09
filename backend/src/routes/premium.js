const express = require('express');
const router = express.Router();
const premiumController = require('../controllers/premiumController');
const { authenticate, isPremium } = require('../middleware/auth');

router.post('/date-night', authenticate, isPremium, premiumController.getDateNight);
router.post('/trip-itinerary', authenticate, isPremium, premiumController.getTripItinerary);

module.exports = router;
