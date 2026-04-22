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
// ELITE SCORING
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
// 💎 ROMANTIC DESCRIPTION ENGINE
// -----------------------------
function romanticDescription(a, b, variant) {
  const styles = [
    `Ease into the evening at ${a.title}, where the atmosphere invites you to slow down and connect. As the night unfolds, wander into ${b.title} and let the moment linger a little longer.`,

    `Begin your night at ${a.title}, a place that naturally sets a warm, intimate tone. From there, drift into ${b.title} and enjoy a quiet, shared moment away from everything else.`,

    `Start with an elegant experience at ${a.title}, where everything feels just a bit more refined. Then continue into ${b.title}, letting the night take on a relaxed, romantic rhythm.`,

    `The night begins at ${a.title}, setting the stage for something special. From there, ${b.title} becomes the perfect place to unwind together and let the evening stretch on.`,

    `Take in the moment at ${a.title}, where the setting naturally draws you closer. Then make your way to ${b.title}, where the night feels calm, intimate, and unhurried.`,
  ];

  return styles[variant % styles.length];
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

      // ⚡ FAST PARALLEL CALLS
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

      // 🚫 NO DUPLICATES
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

      // 🔥 GUARANTEED DIFFERENT DESCRIPTIONS
      const v1 = Math.floor(Math.random() * 5);
      let v2;
      do {
        v2 = Math.floor(Math.random() * 5);
      } while (v2 === v1);

      res.json([
        {
          id: a1.id,
          title: `${a1.title} → ${b1.title}`,
          description: isDateNight
            ? romanticDescription(a1, b1, v1)
            : `Start with ${a1.title}, then head to ${b1.title}.`,
          address: a1.address,
          lat: a1.lat,
          lng: a1.lng,
          photoUrl: a1.photoUrl,
        },
        {
          id: a2.id,
          title: `${a2.title} → ${b2.title}`,
          description: isDateNight
            ? romanticDescription(a2, b2, v2)
            : `Start with ${a2.title}, then head to ${b2.title}.`,
          address: a2.address,
          lat: a2.lat,
          lng: a2.lng,
          photoUrl: a2.photoUrl,
        },
      ]);
    } catch (err) {
      console.error(err);
      res.status(500).send("Error");
    }
  }
);