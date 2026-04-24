import { onRequest } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import fetch from "node-fetch";

console.log("🔥 REAL EXPERIENCE ENGINE v28");

const GOOGLE_API_KEY = defineSecret("GOOGLE_API_KEY");

let usedFood = [];
let usedExp = [];

// 🔥 FILTER REAL RESTAURANTS
function isRestaurant(p) {
  if (!p.types.includes("restaurant")) return false;

  const name = p.name.toLowerCase();

  const banned = [
    "bar","lounge","grill","pub",
    "bbq","smokehouse","buffalo",
    "fast food","pizza","burger"
  ];

  return !banned.some(b => name.includes(b));
}

// 🔥 FETCH RESTAURANTS
async function fetchRestaurants(apiKey, lat, lng) {
  const queries = [
    "fine dining restaurant",
    "romantic restaurant",
    "steakhouse",
    "seafood restaurant"
  ];

  let all = [];

  for (const q of queries) {
    const url = `https://maps.googleapis.com/maps/api/place/textsearch/json?query=${encodeURIComponent(q)}&location=${lat},${lng}&radius=50000&key=${apiKey}`;
    const res = await fetch(url);
    const data = await res.json();
    if (data.results) all = all.concat(data.results);
  }

  return all;
}

// 🔥 FETCH REAL EXPERIENCES
async function fetchExperiences(apiKey, lat, lng, isDateNight) {

  const queries = isDateNight
    ? ["romantic park", "waterfront", "scenic view", "beach"]
    : ["park", "tourist attraction", "bowling alley", "mini golf"];

  let all = [];

  for (const q of queries) {
    const url = `https://maps.googleapis.com/maps/api/place/textsearch/json?query=${encodeURIComponent(q)}&location=${lat},${lng}&radius=50000&key=${apiKey}`;
    const res = await fetch(url);
    const data = await res.json();
    if (data.results) all = all.concat(data.results);
  }

  return all;
}

function pick(arr) {
  return arr[Math.floor(Math.random() * arr.length)];
}

export const getIdeas = onRequest(
  {
    region: "us-central1",
    secrets: [GOOGLE_API_KEY],
  },
  async (req, res) => {

    res.set("Access-Control-Allow-Origin", "*");
    res.set("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
    res.set("Access-Control-Allow-Headers", "Content-Type");

    if (req.method === "OPTIONS") {
      return res.status(204).send("");
    }

    try {
      const data = req.method === "GET" ? req.query : req.body;

      const lat = parseFloat(data?.lat) || 30.8;
      const lng = parseFloat(data?.lng) || -81.7;
      const isDateNight = data?.isDateNight === "true" || data?.isDateNight === true;

      const apiKey = GOOGLE_API_KEY.value();

      // 🔥 RESTAURANTS
      const restaurants = await fetchRestaurants(apiKey, lat, lng);

      let foodOptions = restaurants.filter(p =>
        (p.rating || 0) >= (isDateNight ? 4.5 : 4.2) &&
        (p.user_ratings_total || 0) >= 100 &&
        isRestaurant(p)
      );

      const uniqueFood = Array.from(
        new Map(foodOptions.map(p => [p.place_id, p])).values()
      );

      let availableFood = uniqueFood.filter(p => !usedFood.includes(p.place_id));
      if (availableFood.length === 0) {
        usedFood = [];
        availableFood = uniqueFood;
      }

      const food = pick(availableFood);
      usedFood.push(food.place_id);

      // 🔥 EXPERIENCES (REAL LOCATIONS)
      const experiences = await fetchExperiences(apiKey, lat, lng, isDateNight);

      let expOptions = experiences.filter(p =>
        p.name !== food.name &&
        (p.rating || 0) >= 4.2
      );

      const uniqueExp = Array.from(
        new Map(expOptions.map(p => [p.place_id, p])).values()
      );

      let availableExp = uniqueExp.filter(p => !usedExp.includes(p.place_id));
      if (availableExp.length === 0) {
        usedExp = [];
        availableExp = uniqueExp;
      }

      const exp = pick(availableExp);
      usedExp.push(exp.place_id);

      return res.json([
        {
          title: food.name,
          description: isDateNight
            ? `Enjoy a premium dinner at ${food.name}.`
            : `Start with a meal at ${food.name}.`,
          address: food.formatted_address,
          lat: food.geometry.location.lat,
          lng: food.geometry.location.lng,
          photoUrl: "https://images.unsplash.com/photo-1555396273-367ea4eb4db5",
        },
        {
          title: exp.name,
          description: isDateNight
            ? "A curated romantic destination."
            : "A real activity to continue your outing.",
          address: exp.formatted_address,
          lat: exp.geometry.location.lat,
          lng: exp.geometry.location.lng,
          photoUrl: "https://images.unsplash.com/photo-1507525428034-b723cf961d3e",
        },
      ]);

    } catch (err) {
      console.error(err);
      return res.status(500).json({ error: "Function failed" });
    }
  }
);