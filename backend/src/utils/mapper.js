const mapActivity = (activity) => {
  if (!activity) return null;
  return {
    id: activity.id,
    name: activity.name,
    venue: activity.name, // Lead mentioned both name and venue
    description: activity.description,
    address: activity.address,
    venue_url: activity.website_url,
    website_url: activity.website_url,
    energy_level: activity.energy_level,
    budget: activity.budget,
    estimated_duration: activity.time_needed,
    category: activity.category,
    city: activity.city,
    companion_activity: activity.companion_activity ? mapActivity(activity.companion_activity) : null
  };
};

module.exports = { mapActivity };
