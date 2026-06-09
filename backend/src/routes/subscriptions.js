const express = require('express');
const router = express.Router();
const subscriptionController = require('../controllers/subscriptionController');
const { authenticate } = require('../middleware/auth');

router.post('/', authenticate, express.json(), subscriptionController.createCheckoutSession);
router.post('/webhook', express.raw({type: 'application/json'}), subscriptionController.handleWebhook);

module.exports = router;
