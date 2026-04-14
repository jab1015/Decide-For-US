import { onRequest } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import fetch from "node-fetch";

console.log("🔥 PREMIUM CURATED ENGINE v29");

const GOOGLE_API_KEY = defineSecret("GOOGLE_API_KEY");

let usedFood = [];
let usedExp = [];

// 🔥 STRICT RESTAURANT FILTER
function isRestaurant(p) {
  if (!p.types.includes("restaurant")) return false;

  const name = p.name.toLowerCase();

  const banned = [
    "bar","lounge","grill","pub",
    "bbq","fast food","pizza","burger"
  ];

  return !banned.some(b => name.includes(b));
}

// 🔥 REMOVE LOW QUALITY EXPERIENCES
function isBadExperience(name) {
  const bad = [
    "park","village","playground",
    "community","trail","sports complex"
  ];
  return bad.some(b => name.toLowerCase().includes(b));
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

// 🔥 FETCH PREMIUM EXPERIENCES ONLY
async function fetchExperiences(apiKey, lat, lng, isDateNight) {

  const queries = isDateNight
    ? [
        "waterfront view",
        "scenic overlook",
        "beach access",
        "dessert cafe",
        "nightlife area"
      ]
    : [
        "bowling alley",
        "mini golf",
        "tourist attraction",
        "beach",
        "park"
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

function pick(arr) {
  return arr[Math.floor(Math.random() * arr.length)];
}

// 🔥 MATCH EXPERIENCE TYPE TO RESTAURANT LOCATION
function matchExperience(food, expList) {
  const addr = (food.formatted_address || "").toLowerCase();

  let filtered = expList;

  if (addr.includes("beach")) {
    filtered = expList.filter(e => e.name.toLowerCase().includes("beach"));
  } else if (addr.includes("downtown")) {
    filtered = expList.filter(e => e.name.toLowerCase().includes("downtown"));
  }

  return filtered.length > 0 ? pick(filtered) : pick(expList);
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

      // 🔥 FOOD
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

      // 🔥 EXPERIENCE
      const experiences = await fetchExperiences(apiKey, lat, lng, isDateNight);

      let expOptions = experiences.filter(p =>
        p.name !== food.name &&
        (p.rating || 0) >= 4.2 &&
        (isDateNight ? !isBadExperience(p.name) : true)
      );

      const uniqueExp = Array.from(
        new Map(expOptions.map(p => [p.place_id, p])).values()
      );

      let availableExp = uniqueExp.filter(p => !usedExp.includes(p.place_id));
      if (availableExp.length === 0) {
        usedExp = [];
        availableExp = uniqueExp;
      }

      const exp = matchExperience(food, availableExp);
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
            ? "A curated, high-end experience to elevate your evening."
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