import { onRequest } from "firebase-functions/v2/https";
import { defineString } from "firebase-functions/params";
import fetch from "node-fetch";

const GOOGLE_API_KEY = defineString("GOOGLE_API_KEY");

export const getIdeas = onRequest(
  { region: "us-central1" },
  async (req, res) => {

    res.set("Access-Control-Allow-Origin", "*");
    res.set("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
    res.set("Access-Control-Allow-Headers", "Content-Type");

    if (req.method === "OPTIONS") {
      res.status(204).send("");
      return;
    }

    try {
      const { lat, lng, isDateNight } = req.body || {};

      const centerLat = lat || 30.8;
      const centerLng = lng || -81.6;

      const apiKey = GOOGLE_API_KEY.value();

      // 🔥 TRUE VARIETY (NOT JUST FOOD)
      const queries = isDateNight
        ? [
            "live music",
            "art gallery",
            "cocktail bar",
            "dessert cafe",
            "scenic overlook",
            "walkable downtown",
          ]
        : [
            "things to do",
            "local attractions",
            "parks",
            "bowling",
            "mini golf",
            "museum",
            "arcade",
            "hiking trail",
            "bookstore",
          ];

      let places = [];

      for (const q of queries) {
        const url = `https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${centerLat},${centerLng}&radius=50000&keyword=${encodeURIComponent(q)}&key=${apiKey}`;

        const response = await fetch(url);
        const data = await response.json();

        if (data.results && data.results.length > 0) {
          places = places.concat(data.results);
        }
      }

      if (places.length === 0) {
        return res.json([
          {
            title: "Explore nearby",
            description: "Try expanding your distance or preferences.",
            address: "",
            lat: centerLat,
            lng: centerLng,
          },
        ]);
      }

      function pick(arr) {
        return arr[Math.floor(Math.random() * arr.length)];
      }

      const activities = [
        "grab a drink after",
        "take a scenic walk",
        "watch the sunset",
        "explore nearby shops",
        "get dessert somewhere new",
        "wander and see what you find",
      ];

      const twists = [
        "something you probably wouldn’t normally pick",
        "a different kind of night out",
        "a change from your usual routine",
        "a fun spontaneous choice",
        "an unexpected but great option",
      ];

      function buildExperience(place, isDateNight) {
        if (isDateNight) {
          return `Start at ${place.name}, then ${pick(
            activities
          )}. A ${pick(twists)} for a memorable night together.`;
        }

        return `Check out ${place.name}, then ${pick(
          activities
        )}. It’s ${pick(twists)}.`;
      }

      // 🎯 RANDOMIZE + DEDUPE
      const unique = Array.from(
        new Map(places.map((p) => [p.place_id, p])).values()
      );

      const selected = unique
        .sort(() => 0.5 - Math.random())
        .slice(0, 2);

      const results = selected.map((p) => ({
        title: p.name,
        description: buildExperience(p, isDateNight),
        address: p.vicinity || "Nearby location",
        lat: p.geometry?.location?.lat || 0,
        lng: p.geometry?.location?.lng || 0,
      }));

      res.json(results);

    } catch (err) {
      console.error(err);

      res.json([
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