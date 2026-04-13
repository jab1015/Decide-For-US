import { onRequest } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import fetch from "node-fetch";

const GOOGLE_API_KEY = defineSecret("GOOGLE_API_KEY");

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
      const { lat, lng, isDateNight, radius } = req.body || {};

      const centerLat = lat || 30.8096;
      const centerLng = lng || -81.7105;
      const searchRadius = (radius || 25) * 1609;

      const apiKey = GOOGLE_API_KEY.value();

      const types = ["restaurant", "tourist_attraction"];

      let allPlaces = [];

      for (const type of types) {
        const url = `https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${centerLat},${centerLng}&radius=${searchRadius}&type=${type}&key=${apiKey}`;

        const response = await fetch(url);
        const data = await response.json();

        if (data.results) {
          allPlaces = allPlaces.concat(data.results);
        }
      }

      const chainWords = [
        "chili",
        "applebee",
        "outback",
        "subway",
        "mcdonald",
        "burger king",
        "wendy",
        "taco bell",
      ];

      // ⭐ PREMIUM FILTERING
      let filtered = allPlaces.filter((p) => {
        const name = p.name.toLowerCase();
        const rating = p.rating || 0;
        const reviews = p.user_ratings_total || 0;

        const isChain = chainWords.some((w) => name.includes(w));

        if (isDateNight) {
          return (
            !isChain &&
            rating >= 4.4 &&
            reviews >= 100 &&
            (p.types.includes("restaurant") ||
              p.types.includes("tourist_attraction"))
          );
        }

        return rating >= 4.0;
      });

      if (!filtered.length) filtered = allPlaces;

      const unique = Array.from(
        new Map(filtered.map((p) => [p.place_id, p])).values()
      );

      // 🎯 SPLIT TYPES
      const restaurants = unique.filter((p) =>
        p.types.includes("restaurant")
      );

      const activities = unique.filter((p) =>
        p.types.includes("tourist_attraction")
      );

      const pick = (arr) =>
        arr[Math.floor(Math.random() * arr.length)];

      // 🎯 PREMIUM PAIRING LOGIC
      function createDateNight(food, activity) {
        const styles = [
          () =>
            `Start your evening with a relaxed dinner at ${food.name}, then take a scenic walk around ${activity.name} — perfect for slowing things down together.`,
          () =>
            `Enjoy a cozy meal at ${food.name}, then head to ${activity.name} for a change of pace and a more memorable night.`,
          () =>
            `Kick things off at ${food.name}, then explore ${activity.name} for a fun and effortless date night experience.`,
          () =>
            `A great night starts at ${food.name}, followed by a laid-back visit to ${activity.name} to keep the vibe going.`,
        ];

        return pick(styles)();
      }

      function createStandard(food, activity) {
        return `Check out ${activity.name}, then grab a bite at ${food.name}.`;
      }

      let results = [];

      for (let i = 0; i < 2; i++) {
        const food = pick(restaurants.length ? restaurants : unique);

        let activityPool = activities.length ? activities : unique;

        const activity = pick(activityPool);

        const description = isDateNight
          ? createDateNight(food, activity)
          : createStandard(food, activity);

        results.push({
          title: food.name,
          description,
          address: food.vicinity || "",
          lat: food.geometry.location.lat,
          lng: food.geometry.location.lng,
        });
      }

      return res.json(results);
    } catch (err) {
      console.error("ERROR:", err);

      return res.json([
        {
          title: "Error",
          description: "Something went wrong.",
          address: "",
          lat: 0,
          lng: 0,
        },
      ]);
    }
  }
);