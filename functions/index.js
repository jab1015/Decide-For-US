import { onRequest } from "firebase-functions/v2/https";
import axios from "axios";

const GOOGLE_API_KEY = process.env.GOOGLE_API_KEY;

/* ---------------- MEMORY ---------------- */

const recentPlaces = new Set();

/* ---------------- HELPERS ---------------- */

const rand = (arr) => arr[Math.floor(Math.random() * arr.length)];
const shuffle = (arr) => arr.sort(() => 0.5 - Math.random());

/* ---------------- SEARCH ---------------- */

const searchPlaces = async (keyword, lat, lng, radius) => {
  const res = await axios.get(
    "https://maps.googleapis.com/maps/api/place/nearbysearch/json",
    {
      params: {
        keyword,
        location: `${lat},${lng}`,
        radius: radius * 1609,
        key: GOOGLE_API_KEY,
      },
    }
  );

  return res.data.results || [];
};

const pickPlace = async (keywords, lat, lng, radius) => {
  for (let k of shuffle(keywords)) {
    const results = await searchPlaces(k, lat, lng, radius);

    const filtered = results
      .filter(
        (p) =>
          p.rating >= 4.2 &&
          (p.user_ratings_total || 0) > 40 &&
          !recentPlaces.has(p.place_id)
      )
      .sort((a, b) => b.rating - a.rating);

    if (filtered.length) {
      const chosen = filtered[0];
      recentPlaces.add(chosen.place_id);
      if (recentPlaces.size > 50) recentPlaces.clear();
      return chosen;
    }
  }
  return null;
};

/* ---------------- TYPE DETECTION ---------------- */

function getVibe(place) {
  const types = place.types || [];

  if (types.includes("park") || types.includes("tourist_attraction"))
    return "outdoor";

  if (types.includes("museum") || types.includes("art_gallery"))
    return "culture";

  if (types.includes("cafe") || types.includes("restaurant"))
    return "food";

  if (types.includes("bar"))
    return "drinks";

  return "generic";
}

/* ---------------- SMART PAIRING ---------------- */

async function getDatePair(lat, lng, radius) {
  // STEP A: scenic / experience
  const A = await pickPlace(
    ["scenic overlook", "waterfront", "garden", "museum", "trail"],
    lat,
    lng,
    radius
  );

  if (!A) return null;

  const coord = A.geometry.location;
  const vibe = getVibe(A);

  let secondKeywords;

  if (vibe === "outdoor") {
    secondKeywords = ["dessert", "wine bar", "cafe", "rooftop"];
  } else if (vibe === "culture") {
    secondKeywords = ["wine bar", "dessert", "cafe"];
  } else {
    secondKeywords = ["dessert", "lounge", "bar"];
  }

  const B = await pickPlace(secondKeywords, coord.lat, coord.lng, 3);

  if (!B) return null;

  return { A, B };
}

/* ---------------- DESCRIPTION ENGINE ---------------- */

function describe(a, b, mode) {
  const vibeA = getVibe(a);
  const vibeB = getVibe(b);

  const openers = [
    `Start at ${a.name}`,
    `Begin your time at ${a.name}`,
    `Ease into the evening at ${a.name}`,
    `Take a moment at ${a.name}`,
  ];

  const transitions = [
    `then head to ${b.name}`,
    `before making your way to ${b.name}`,
    `and continue on to ${b.name}`,
    `then slip over to ${b.name}`,
  ];

  const outdoorLines = [
    `take your time and enjoy the surroundings`,
    `slow things down and take it all in`,
    `let the moment breathe a bit`,
  ];

  const cozyLines = [
    `settle in somewhere a little more relaxed`,
    `shift into something more intimate`,
    `wind down together`,
  ];

  let middle;

  if (vibeA === "outdoor") {
    middle = rand(outdoorLines);
  } else {
    middle = "ease into the experience";
  }

  let ending;

  if (vibeB === "food") {
    ending = rand([
      `and enjoy something sweet together.`,
      `and grab something to share.`,
      `and relax over something light.`,
    ]);
  } else if (vibeB === "drinks") {
    ending = rand([
      `and unwind for a bit.`,
      `and let the night settle in.`,
      `and keep things easy and relaxed.`,
    ]);
  } else {
    ending = rand(cozyLines) + ".";
  }

  const structures = [
    `${rand(openers)}, ${middle}, ${rand(transitions)} ${ending}`,
    `${rand(openers)}. ${middle}, ${rand(transitions)} ${ending}`,
    `${rand(openers)} — ${middle}, ${rand(transitions)} ${ending}`,
  ];

  return rand(structures);
}

/* ---------------- MAIN ---------------- */

export const getIdeas = onRequest(async (req, res) => {
  try {
    const { lat, lng, radius = 25, isDateNight, budget } = req.body;

    if (!lat || !lng) return res.json([]);

    const results = [];
    let attempts = 0;

    while (results.length < 2 && attempts < 10) {
      attempts++;

      let pair;

      if (isDateNight) {
        pair = await getDatePair(lat, lng, radius);
      } else if (budget === "Free") {
        pair = await getDatePair(lat, lng, radius); // reuse but still filtered by keywords
      } else {
        pair = await getDatePair(lat, lng, radius);
      }

      if (!pair) continue;

      const { A, B } = pair;

      const coordA = A.geometry.location;

      const photoUrl = A.photos?.[0]
        ? `https://maps.googleapis.com/maps/api/place/photo?maxwidth=800&photo_reference=${A.photos[0].photo_reference}&key=${GOOGLE_API_KEY}`
        : null;

      results.push({
        id: `${A.place_id}_${B.place_id}`,
        title: `${A.name} → ${B.name}`,
        description: describe(A, B, "date"),
        address: A.vicinity || "",
        lat: coordA.lat,
        lng: coordA.lng,
        photoUrl,
      });
    }

    res.json(results);
  } catch (err) {
    console.error(err);
    res.json([]);
  }
});