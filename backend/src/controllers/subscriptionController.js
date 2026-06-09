const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
const { query } = require('../db');

const createCheckoutSession = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { plan } = req.body;

    let priceId;
    if (plan === 'annual') {
      priceId = process.env.PRICE_ID_ANNUAL;
    } else {
      // Default to monthly if not specified or monthly requested
      priceId = process.env.PRICE_ID_MONTHLY;
    }

    if (!priceId) {
      return res.status(400).json({ error: 'Price ID not configured for this plan' });
    }

    const session = await stripe.checkout.sessions.create({
      payment_method_types: ['card'],
      line_items: [
        {
          price: priceId,
          quantity: 1,
        },
      ],
      mode: 'subscription',
      success_url: `${process.env.FRONTEND_URL}/success?session_id={CHECKOUT_SESSION_ID}`,
      cancel_url: `${process.env.FRONTEND_URL}/cancel`,
      client_reference_id: userId,
      metadata: {
        userId: userId,
        plan: plan || 'monthly'
      }
    });

    res.json({ url: session.url });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
};

const handleWebhook = async (req, res) => {
  const sig = req.headers['stripe-signature'];
  let event;

  try {
    event = stripe.webhooks.constructEvent(req.body, sig, process.env.STRIPE_WEBHOOK_SECRET);
  } catch (err) {
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  if (event.type === 'checkout.session.completed') {
    const session = event.data.object;
    const userId = session.client_reference_id;
    const stripeSubscriptionId = session.subscription;
    const plan = session.metadata.plan || 'monthly';

    const existing = await query(`SELECT id FROM subscriptions WHERE user_id = '${userId}'`);
    
    if (existing.length > 0) {
      await query(`UPDATE subscriptions SET plan = '${plan}', stripe_subscription_id = '${stripeSubscriptionId}', status = 'active' WHERE user_id = '${userId}'`);
    } else {
      const id = require('uuid').v4();
      await query(`INSERT INTO subscriptions (id, user_id, plan, stripe_subscription_id, status) VALUES ('${id}', '${userId}', '${plan}', '${stripeSubscriptionId}', 'active')`);
    }
    console.log(`User ${userId} upgraded to ${plan}`);
  }

  res.json({ received: true });
};

module.exports = {
  createCheckoutSession,
  handleWebhook
};
