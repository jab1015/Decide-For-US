const jwt = require('jsonwebtoken');
const { query } = require('../db');

const authenticate = (req, res, next) => {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'No token provided' });
  }

  const token = authHeader.split(' ')[1];

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded;
    next();
  } catch (error) {
    return res.status(401).json({ error: 'Invalid or expired token' });
  }
};

const isPremium = async (req, res, next) => {
  try {
    const userId = req.user.userId;
    const subscriptions = await query(`SELECT plan FROM subscriptions WHERE user_id = '${userId}' AND status = 'active'`);
    
    const isPremiumPlan = (plan) => {
      if (!plan) return false;
      return plan.startsWith('premium') || plan === 'monthly' || plan === 'annual';
    };
    
    if (subscriptions.length > 0 && isPremiumPlan(subscriptions[0].plan)) {
      return next();
    }
    
    res.status(403).json({ 
      error: 'Premium required', 
      message: 'This feature is only available for NearVibe Premium subscribers.' 
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
};

module.exports = {
  authenticate,
  isPremium
};
