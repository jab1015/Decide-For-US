const express = require('express');
const router = express.Router();
const suggestionController = require('../controllers/suggestionController');
const { authenticate } = require('../middleware/auth');

router.get('/:id', authenticate, suggestionController.getVenueDetails);

module.exports = router;
