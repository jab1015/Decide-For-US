const { query } = require('../db');
const { v4: uuidv4 } = require('uuid');
const { mapActivity } = require('../utils/mapper');

const getWeekStart = () => {
  const now = new Date();
  const day = now.getDay();
  const diff = now.getDate() - day + (day === 0 ? -6 : 1);
  const monday = new Date(now.setDate(diff));
  monday.setHours(0, 0, 0, 0);
  return monday.toISOString().split('T')[0];
};

const getSuggestions = async (req, res) => {
  try {
    const { distance, time, energy_level, budget, city } = req.body;
    const userId = req.user.userId;

    // 1. Get user info and all activities in one or two calls
    const weekStart = getWeekStart();
    const userData = await query(`
      SELECT s.plan, u.count 
      FROM (SELECT '${userId}' as id) r
      LEFT JOIN subscriptions s ON s.user_id = r.id
      LEFT JOIN usage_tracking u ON u.user_id = r.id AND u.week_start = '${weekStart}'
    `);
    
    const plan = userData[0]?.plan || 'free';
    const isPremium = plan && (plan.startsWith('premium') || plan === 'monthly' || plan === 'annual');
    const count = userData[0]?.count || 0;

    if (!isPremium && count >= 3) {
      return res.status(403).json({
        error: 'Weekly limit reached',
        message: 'Free users are limited to 3 suggestions per week. Upgrade to Premium for unlimited access!'
      });
    }

    // 2. Fetch all suitable suggestions
    let sql = `SELECT * FROM activity_suggestions WHERE 1=1`;
    if (city) sql += ` AND city = '${city}'`;
    if (distance) sql += ` AND distance <= ${distance}`;
    if (time) sql += ` AND time_needed <= ${time}`;
    if (energy_level) sql += ` AND energy_level = '${energy_level}'`;
    if (budget) sql += ` AND budget <= ${budget}`;

    const allSuitable = await query(sql);
    
    if (allSuitable.length === 0) {
      return res.json({ suggestions: [], message: "No activities found matching your filters." });
    }

    // Shuffle and pick up to 3
    const shuffled = allSuitable.sort(() => 0.5 - Math.random());
    const suggestions = shuffled.slice(0, 3);

    // 3. Companion logic (find another activity in the same city)
    const results = await Promise.all(suggestions.map(async (activity) => {
      // For companion, look for something in the same city if not enough in allSuitable
      let companionCandidates = allSuitable.filter(a => a.id !== activity.id);
      
      if (companionCandidates.length === 0) {
        // Fallback: search DB for anything in the same city
        companionCandidates = await query(`SELECT * FROM activity_suggestions WHERE city = '${activity.city}' AND id != '${activity.id}' LIMIT 5`);
      }
      
      const companion = companionCandidates.length > 0 
        ? companionCandidates[Math.floor(Math.random() * companionCandidates.length)]
        : null;
      
      return {
        ...activity,
        companion_activity: companion
      };
    }));

    // 4. Update usage
    const currentCount = await query(`SELECT count FROM usage_tracking WHERE user_id = '${userId}' AND week_start = '${weekStart}'`);
    if (currentCount.length > 0) {
      await query(`UPDATE usage_tracking SET count = count + 1 WHERE user_id = '${userId}' AND week_start = '${weekStart}'`);
    } else {
      await query(`INSERT INTO usage_tracking (id, user_id, week_start, count) VALUES ('${uuidv4()}', '${userId}', '${weekStart}', 1)`);
    }

    res.json({
      suggestions: results.map(a => mapActivity(a)),
      remaining_free_uses: !isPremium ? Math.max(0, 3 - count - 1) : 'unlimited'
    });

  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Internal Server Error', message: error.message });
  }
};

const getUsage = async (req, res) => {
  try {
    const userId = req.user.userId;
    const weekStart = getWeekStart();
    
    const userData = await query(`
      SELECT s.plan, u.count 
      FROM (SELECT '${userId}' as id) r
      LEFT JOIN subscriptions s ON s.user_id = r.id
      LEFT JOIN usage_tracking u ON u.user_id = r.id AND u.week_start = '${weekStart}'
    `);

    const plan = userData[0]?.plan || 'free';
    const isPremium = plan && (plan.startsWith('premium') || plan === 'monthly' || plan === 'annual');
    const count = userData[0]?.count || 0;

    res.json({
      plan: plan,
      isPremium: isPremium,
      current_weekly_usage: count,
      remaining_free_uses: isPremium ? 'unlimited' : Math.max(0, 3 - count),
      week_start: weekStart,
      limit: 3
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
};

const getVenueDetails = async (req, res) => {
  try {
    const { id } = req.params;
    const venue = await query(`SELECT * FROM activity_suggestions WHERE id = '${id}'`);
    
    if (venue.length === 0) {
      return res.status(404).json({ error: 'Venue not found' });
    }
    
    res.json(venue[0]);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
};

module.exports = {
  getSuggestions,
  getUsage,
  getVenueDetails
};
