const express = require('express');
console.log('auth routes file executing');
const router = express.Router();
const authController = require('../controllers/authController');
const { authenticate } = require('../middleware/auth');

router.post('/register', authController.register);
router.post('/login', authController.login);
router.get('/me', authenticate, authController.getMe);
router.post('/request-consent', authenticate, authController.requestParentalConsent);
router.post('/verify-consent', authController.verifyParentalConsent);

module.exports = router;
