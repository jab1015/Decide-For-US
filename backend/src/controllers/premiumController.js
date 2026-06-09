const { query } = require('../db');
const { mapActivity } = require('../utils/mapper');

const getDateNight = async (req, res) => {
  try {
    const { city, budget, romantic_level } = req.body;
    
    // Logic for date night: Pick a nice food venue and a companion activity
    let sql = `SELECT * FROM activity_suggestions WHERE 1=1`;
    if (city) sql += ` AND city = '${city}'`;
    if (budget) sql += ` AND budget <= ${budget}`;
    
    // For date night, prefer Food category for the primary activity
    const foodVenues = await query(sql + ` AND category = 'Food' ORDER BY RANDOM() LIMIT 1`);
    
    let primary = foodVenues.length > 0 ? foodVenues[0] : null;
    
    if (!primary) {
      // Fallback to any activity in that city
      const anyVenues = await query(sql + ` ORDER BY RANDOM() LIMIT 1`);
      primary = anyVenues.length > 0 ? anyVenues[0] : null;
    }
    
    if (!primary) {
      return res.json({ suggestions: [], message: "No activities found for your date night." });
    }
    
    // Find a companion (Culture or Outdoor for date variety)
    const companions = await query(`
      SELECT * FROM activity_suggestions 
      WHERE city = '${primary.city}' AND id != '${primary.id}'
      ORDER BY RANDOM() LIMIT 1
    `);
    
    primary.companion_activity = companions.length > 0 ? companions[0] : null;
    
    res.json({
      suggestions: [mapActivity(primary)]
    });
    
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
};

const getTripItinerary = async (req, res) => {
  try {
    const { city, days = 3 } = req.body;
    
    const allActivities = await query(`SELECT * FROM activity_suggestions WHERE city = '${city}'`);
    
    if (allActivities.length === 0) {
      return res.json({ itinerary: [] });
    }
    
    const itinerary = [];
    for (let i = 1; i <= days; i++) {
      // Pick 2-3 activities per day
      const dailyActivities = allActivities
        .sort(() => 0.5 - Math.random())
        .slice(0, 3)
        .map(a => mapActivity(a));
        
      itinerary.push({
        day: i,
        activities: dailyActivities
      });
    }
    
    res.json({ itinerary });
    
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
};

module.exports = {
  getDateNight,
  getTripItinerary
};
