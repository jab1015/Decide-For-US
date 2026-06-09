const express = require('express');
const router = express.Router();
const suggestionController = require('../controllers/suggestionController');
const { authenticate } = require('../middleware/auth');

router.post('/', authenticate, suggestionController.getSuggestions);
router.get('/usage', authenticate, suggestionController.getUsage);

module.exports = router;
