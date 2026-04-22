import { onRequest } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";

const GOOGLE_API_KEY = defineSecret("GOOGLE_API_KEY");

// -----------------------------
// PHOTO PROXY
// -----------------------------
export const getPhoto = onRequest(
  { cors: true, secrets: [GOOGLE_API_KEY] },
  async (req, res) => {
    try {
      const ref = req.query.ref;
      const key = GOOGLE_API_KEY.value();

      const url = `https://maps.googleapis.com/maps/api/place/photo?maxwidth=800&photo_reference=${ref}&key=${key}`;
      const response = await fetch(url, { redirect: "follow" });

      const buffer = await response.arrayBuffer();
      res.set("Content-Type", response.headers.get("content-type"));
      res.send(Buffer.from(buffer));
    } catch {
      res.redirect("https://images.unsplash.com/photo-1504674900247-0877df9cc836");
    }
  }
);

// -----------------------------
// SCORING
// -----------------------------
function eliteScore(p) {
  let score = (p.rating || 0) * 4;
  const n = p.name.toLowerCase();

  if (n.includes("steak")) score += 10;
  if (n.includes("seafood")) score += 10;
  if (n.includes("rooftop")) score += 12;
  if (n.includes("wine")) score += 10;
  if (n.includes("cocktail")) score += 10;
  if (n.includes("lounge")) score += 10;
  if (n.includes("view")) score += 12;
  if (n.includes("water")) score += 10;

  if (n.includes("pizza")) score -= 20;
  if (n.includes("burger")) score -= 20;
  if (n.includes("fast")) score -= 30;

  return score;
}

// -----------------------------
// UNIQUE DESCRIPTION GENERATOR
// -----------------------------
function romanticDescription(a, b, variant = 1) {
  const options = [
    `Begin the evening at ${a.title} with an intimate, romantic atmosphere, then continue to ${b.title} for a memorable and elevated experience together.`,
    `Start with a cozy, romantic moment at ${a.title}, then head to ${b.title} to deepen the connection and enjoy the night.`,
    `Enjoy a refined and intimate start at ${a.title}, followed by ${b.title} where the evening becomes truly special.`,
    `Kick off the night at ${a.title} with a warm, romantic setting, then transition into ${b.title} for a perfect continuation.`,
  ];

  return options[variant % options.length];
}

// -----------------------------
// MAIN
// -----------------------------
export const getIdeas = onRequest(
  { cors: true, secrets: [GOOGLE_API_KEY] },
  async (req, res) => {
    try {
      const { lat, lng, isDateNight, radius = 25 } = req.body;
      const key = GOOGLE_API_KEY.value();

      const latitude = lat || 30.3322;
      const longitude = lng || -81.6557;
      const radiusMeters = radius * 1609;

      const buildUrl = (query) =>
        `https://maps.googleapis.com/maps/api/place/textsearch/json?query=${encodeURIComponent(query)}&location=${latitude},${longitude}&radius=${radiusMeters}&key=${key}`;

      const [foodRes, expRes] = await Promise.all([
        fetch(buildUrl(
          isDateNight
            ? "fine dining steakhouse romantic upscale restaurant"
            : "restaurant"
        )),
        fetch(buildUrl(
          isDateNight
            ? "rooftop bar scenic cocktail lounge waterfront"
            : "things to do"
        )),
      ]);

      const foodData = await foodRes.json();
      const expData = await expRes.json();

      let food = foodData.results || [];
      let exp = expData.results || [];

      const clean = (p) =>
        p.name &&
        p.rating >= (isDateNight ? 4.4 : 4.0) &&
        p.user_ratings_total > (isDateNight ? 120 : 50) &&
        p.photos &&
        p.photos.length > 0;

      food = food.filter(clean);
      exp = exp.filter(clean);

      if (isDateNight) {
        food = food
          .map(p => ({ ...p, score: eliteScore(p) }))
          .filter(p => p.score > 40)
          .sort((a, b) => b.score - a.score)
          .slice(0, 6);

        exp = exp
          .map(p => ({ ...p, score: eliteScore(p) }))
          .filter(p => p.score > 40)
          .sort((a, b) => b.score - a.score)
          .slice(0, 6);
      }

      if (!food.length || !exp.length) {
        return res.json([]);
      }

      // 🔥 ENSURE UNIQUE PICKS
      const usedIds = new Set();

      const pickUnique = (list) => {
        let item;
        do {
          item = list[Math.floor(Math.random() * list.length)];
        } while (usedIds.has(item.place_id));

        usedIds.add(item.place_id);
        return item;
      };

      const f1 = pickUnique(food);
      const e1 = pickUnique(exp);
      const f2 = pickUnique(food);
      const e2 = pickUnique(exp);

      const getPhotoUrl = (p) => {
        const ref = p.photos?.[0]?.photo_reference;
        return ref
          ? `https://us-central1-decide-for-us-792bc.cloudfunctions.net/getPhoto?ref=${ref}`
          : null;
      };

      const build = (p) => ({
        id: p.place_id,
        title: p.name,
        address: p.formatted_address || p.vicinity,
        lat: p.geometry.location.lat,
        lng: p.geometry.location.lng,
        photoUrl: getPhotoUrl(p),
      });

      const a1 = build(f1);
      const b1 = build(e1);
      const a2 = build(f2);
      const b2 = build(e2);

      res.json([
        {
          ...combine(a1, b1),
          description: isDateNight
            ? romanticDescription(a1, b1, 1)
            : `Start with ${a1.title}, then head to ${b1.title}.`,
        },
        {
          ...combine(a2, b2),
          description: isDateNight
            ? romanticDescription(a2, b2, 2)
            : `Start with ${a2.title}, then head to ${b2.title}.`,
        },
      ]);
    } catch (err) {
      res.status(500).send("Error");
    }
  }
);

// -----------------------------
function combine(a, b) {
  return {
    id: a.id,
    title: `${a.title} → ${b.title}`,
    address: a.address,
    lat: a.lat,
    lng: a.lng,
    photoUrl: a.photoUrl,
  };
}