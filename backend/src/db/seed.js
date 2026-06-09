const { query } = require('../db');
const { v4: uuidv4 } = require('uuid');

const seedVenues = async () => {
  const venues = [
    // Austin
    {
      name: "Barton Springs Pool",
      description: "Natural spring-fed pool with year-round 68-degree water.",
      address: "2131 William Barton Dr, Austin, TX 78746",
      city: "Austin",
      website_url: "https://www.austintexas.gov/department/barton-springs-pool",
      distance: 2.5,
      time_needed: 2,
      energy_level: "medium",
      budget: 5,
      category: "Outdoor"
    },
    {
      name: "Zilker Metropolitan Park",
      description: "Large urban park with picnic areas, trails, and views of the skyline.",
      address: "2207 Lou Neff Rd, Austin, TX 78746",
      city: "Austin",
      website_url: "https://www.austintexas.gov/zilkerpark",
      distance: 2.3,
      time_needed: 1,
      energy_level: "low",
      budget: 0,
      category: "Outdoor"
    },
    {
      name: "Franklin Barbecue",
      description: "World-famous BBQ joint known for its brisket.",
      address: "900 E 11th St, Austin, TX 78702",
      city: "Austin",
      website_url: "https://franklinbbq.com/",
      distance: 1.2,
      time_needed: 3,
      energy_level: "medium",
      budget: 30,
      category: "Food"
    },
    // NYC
    {
      name: "Central Park",
      description: "Iconic park in the heart of Manhattan.",
      address: "New York, NY",
      city: "NYC",
      website_url: "https://www.centralparknyc.org/",
      distance: 0,
      time_needed: 3,
      energy_level: "medium",
      budget: 0,
      category: "Outdoor"
    },
    {
      name: "The Metropolitan Museum of Art",
      description: "One of the world's largest and finest art museums.",
      address: "1000 5th Ave, New York, NY 10028",
      city: "NYC",
      website_url: "https://www.metmuseum.org/",
      distance: 0.5,
      time_needed: 4,
      energy_level: "medium",
      budget: 25,
      category: "Culture"
    }
  ];

  for (const venue of venues) {
    const id = uuidv4();
    const escape = (str) => typeof str === 'string' ? str.replace(/'/g, "''") : str;
    await query(`INSERT INTO activity_suggestions (id, name, description, address, city, website_url, distance, time_needed, energy_level, budget, category) VALUES ('${id}', '${escape(venue.name)}', '${escape(venue.description)}', '${escape(venue.address)}', '${escape(venue.city)}', '${escape(venue.website_url)}', ${venue.distance}, ${venue.time_needed}, '${escape(venue.energy_level)}', ${venue.budget}, '${escape(venue.category)}')`);
  }
  console.log("Seeded venues successfully");
};

module.exports = { seedVenues };
