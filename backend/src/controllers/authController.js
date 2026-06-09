const { query } = require('../db');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');

const register = async (req, res) => {
  try {
    const { email, password, age } = req.body;

    if (!email || !password || !age) {
      return res.status(400).json({ error: 'Email, password, and age are required' });
    }

    // Check if user exists
    const existingUser = await query(`SELECT * FROM users WHERE email = '${email}'`);
    if (existingUser.length > 0) {
      return res.status(400).json({ error: 'User already exists' });
    }

    const passwordHash = await bcrypt.hash(password, 10);
    const userId = uuidv4();

    // Create user
    await query(`INSERT INTO users (id, email, password_hash, age) VALUES ('${userId}', '${email}', '${passwordHash}', ${age})`);

    // Handle age verification for Texas SCOPE Act (if age < 18)
    let verificationStatus = 'verified';
    if (age < 18) {
      verificationStatus = 'pending';
      const verificationId = uuidv4();
      await query(`INSERT INTO age_verification (id, user_id, status) VALUES ('${verificationId}', '${userId}', 'pending')`);
    }

    // Default subscription
    const subId = uuidv4();
    await query(`INSERT INTO subscriptions (id, user_id, plan, status) VALUES ('${subId}', '${userId}', 'free', 'active')`);

    res.status(201).json({
      message: 'User registered successfully',
      userId,
      verificationStatus
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
};

const login = async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required' });
    }

    const users = await query(`SELECT * FROM users WHERE email = '${email}'`);
    if (users.length === 0) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const user = users[0];
    const isMatch = await bcrypt.compare(password, user.password_hash);
    if (!isMatch) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const token = jwt.sign(
      { userId: user.id, email: user.email, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: '24h' }
    );

    res.json({
      token,
      user: {
        id: user.id,
        email: user.email,
        age: user.age,
        role: user.role
      }
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
};

const getMe = async (req, res) => {
  try {
    const users = await query(`SELECT id, email, age, role FROM users WHERE id = '${req.user.userId}'`);
    if (users.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    const user = users[0];
    const verifications = await query(`SELECT status FROM age_verification WHERE user_id = '${user.id}'`);
    const verificationStatus = verifications.length > 0 ? verifications[0].status : 'verified';

    const subscriptions = await query(`SELECT plan FROM subscriptions WHERE user_id = '${user.id}'`);
    const plan = subscriptions.length > 0 ? subscriptions[0].plan : 'free';

    res.json({
      ...user,
      verificationStatus,
      plan
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
};

const requestParentalConsent = async (req, res) => {
  try {
    const { parentEmail } = req.body;
    if (!parentEmail) {
      return res.status(400).json({ error: 'Parent email is required' });
    }

    await query(`UPDATE age_verification SET parent_email = '${parentEmail}', status = 'awaiting_consent' WHERE user_id = '${req.user.userId}'`);

    // In a real app, we would send an email here.
    res.json({ message: 'Parental consent request sent' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
};

const verifyParentalConsent = async (req, res) => {
  try {
    const { userId } = req.body; // In a real app, this would be validated via a secure token from email
    if (!userId) {
      return res.status(400).json({ error: 'User ID is required' });
    }

    await query(`UPDATE age_verification SET status = 'verified', verified_at = CURRENT_TIMESTAMP WHERE user_id = '${userId}'`);

    res.json({ message: 'Parental consent verified successfully' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
};

module.exports = {
  register,
  login,
  getMe,
  requestParentalConsent,
  verifyParentalConsent
};
