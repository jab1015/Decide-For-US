import {initializeApp} from "firebase-admin/app";
import {getAuth} from "firebase-admin/auth";
import {FieldValue, getFirestore} from "firebase-admin/firestore";
import {defineSecret} from "firebase-functions/params";
import {onRequest} from "firebase-functions/v2/https";
import fetch from "node-fetch";

initializeApp();

const GOOGLE_API_KEY = defineSecret("GOOGLE_API_KEY");
const REVENUECAT_SECRET_API_KEY = defineSecret("REVENUECAT_SECRET_API_KEY");
const FREE_WEEKLY_LIMIT = 3;

const foodQueries = {
  Free: ["affordable restaurant", "casual restaurant"],
  "$": ["casual restaurant", "local restaurant"],
  "$$": ["upscale restaurant", "fine dining restaurant"],
};

const activityQueries = {
  Low: ["museum", "art gallery", "scenic view", "bookstore"],
  Medium: ["bowling alley", "mini golf", "live music", "tourist attraction"],
  High: ["hiking trail", "kayaking", "rock climbing", "adventure park"],
};

function milesToMeters(miles) {
  return Math.min(Math.max(Number(miles) || 25, 1) * 1609, 50000);
}

function priceAllowed(place, budget) {
  if (budget === "Free") return place.price_level == null || place.price_level === 0;
  if (budget === "$") return place.price_level == null || place.price_level <= 2;
  if (budget === "$$") return place.price_level == null || place.price_level <= 3;
  return true;
}

function rank(place) {
  return (place.rating || 0) * Math.log10((place.user_ratings_total || 0) + 10);
}

function uniqueRanked(places) {
  return [...new Map(places.map((place) => [place.place_id, place])).values()]
    .filter((place) => place.place_id && place.geometry?.location)
    .filter((place) => (place.rating || 0) >= 4)
    .sort((a, b) => rank(b) - rank(a));
}

async function searchPlaces(apiKey, queries, lat, lng, radius) {
  const results = await Promise.all(queries.map(async (query) => {
    const params = new URLSearchParams({
      query,
      location: `${lat},${lng}`,
      radius: String(radius),
      key: apiKey,
    });
    const response = await fetch(
      `https://maps.googleapis.com/maps/api/place/textsearch/json?${params}`,
    );
    const payload = await response.json();
    if (!response.ok || !["OK", "ZERO_RESULTS"].includes(payload.status)) {
      throw new Error(`Google Places error: ${payload.status || response.status}`);
    }
    return payload.results || [];
  }));
  return uniqueRanked(results.flat());
}

function activityCategory(place) {
  const types = new Set(place.types || []);
  if (types.has("museum") || types.has("art_gallery")) return "culture";
  if (types.has("park") || types.has("natural_feature")) return "outdoors";
  if (types.has("movie_theater") || types.has("night_club")) return "entertainment";
  return "experience";
}

function serialize(place, category, description) {
  return {
    id: place.place_id,
    category,
    title: place.name,
    description,
    address: place.formatted_address || "",
    lat: place.geometry.location.lat,
    lng: place.geometry.location.lng,
    photoUrl: null,
  };
}

async function authenticatedUser(req) {
  const authorization = req.get("Authorization") || "";
  if (!authorization.startsWith("Bearer ")) return null;
  return getAuth().verifyIdToken(authorization.slice(7));
}

async function hasPremium(uid, apiKey) {
  if (!apiKey) return false;
  const response = await fetch(
    `https://api.revenuecat.com/v1/subscribers/${encodeURIComponent(uid)}`,
    {headers: {Authorization: `Bearer ${apiKey}`}},
  );
  if (!response.ok) return false;
  const payload = await response.json();
  const entitlement = payload.subscriber?.entitlements?.premium;
  if (!entitlement) return false;
  return !entitlement.expires_date || new Date(entitlement.expires_date) > new Date();
}

function weekKey(date = new Date()) {
  const first = new Date(Date.UTC(date.getUTCFullYear(), 0, 1));
  const day = Math.floor((date - first) / 86400000);
  return `${date.getUTCFullYear()}-${Math.ceil((day + first.getUTCDay() + 1) / 7)}`;
}

async function consumeFreeRequest(uid) {
  const reference = getFirestore().collection("recommendation_usage")
    .doc(`${uid}_${weekKey()}`);
  await getFirestore().runTransaction(async (transaction) => {
    const snapshot = await transaction.get(reference);
    const count = snapshot.data()?.count || 0;
    if (count >= FREE_WEEKLY_LIMIT) {
      const error = new Error("Free weekly limit reached.");
      error.status = 403;
      throw error;
    }
    transaction.set(reference, {
      uid,
      count: FieldValue.increment(1),
      week: weekKey(),
      updatedAt: FieldValue.serverTimestamp(),
    }, {merge: true});
  });
}

export const getIdeas = onRequest(
  {
    region: "us-central1",
    secrets: [GOOGLE_API_KEY, REVENUECAT_SECRET_API_KEY],
  },
  async (req, res) => {
    res.set("Access-Control-Allow-Origin", "*");
    res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
    res.set("Access-Control-Allow-Headers", "Authorization, Content-Type");
    if (req.method === "OPTIONS") return res.status(204).send("");
    if (req.method !== "POST") return res.status(405).json({error: "POST required."});

    try {
      const user = await authenticatedUser(req);
      if (!user) return res.status(401).json({error: "Authentication required."});

      const premium = await hasPremium(user.uid, REVENUECAT_SECRET_API_KEY.value());
      const isDateNight = req.body?.isDateNight === true;
      if (isDateNight && !premium) {
        return res.status(403).json({error: "Date Night+ requires Premium."});
      }
      const lat = Number(req.body?.lat);
      const lng = Number(req.body?.lng);
      if (!Number.isFinite(lat) || !Number.isFinite(lng)) {
        return res.status(400).json({error: "A valid location is required."});
      }

      const budget = req.body?.budget || "$";
      const energy = req.body?.energy || "Medium";
      const group = req.body?.group || "Couple";
      const radius = milesToMeters(req.body?.radius);
      const googleKey = GOOGLE_API_KEY.value();

      const foodTerms = isDateNight
        ? ["romantic restaurant", "fine dining restaurant"]
        : (foodQueries[budget] || foodQueries["$"]);
      const experienceTerms = isDateNight
        ? ["romantic activity", "live music", "scenic view", "art gallery"]
        : (activityQueries[energy] || activityQueries.Medium)
            .map((term) => group === "Family" ? `family friendly ${term}` : term);

      const [food, experiences] = await Promise.all([
        searchPlaces(googleKey, foodTerms, lat, lng, radius),
        searchPlaces(googleKey, experienceTerms, lat, lng, radius),
      ]);

      const foodChoice = budget === "Free" ?
        null :
        food.find((place) => priceAllowed(place, budget));
      const firstExperience = experiences[0];
      const secondExperience = experiences.find(
        (place) => activityCategory(place) !== activityCategory(firstExperience || {}),
      );

      let pair;
      if (isDateNight || !secondExperience) {
        pair = [foodChoice, firstExperience].filter(Boolean);
      } else {
        pair = Math.random() < 0.5 && foodChoice
          ? [foodChoice, firstExperience]
          : [firstExperience, secondExperience];
      }

      if (pair.length < 2) {
        return res.status(404).json({
          error: "We could not find two strong, different options nearby.",
        });
      }

      if (!premium) await consumeFreeRequest(user.uid);

      return res.json(pair.map((place) => {
        const isFood = place === foodChoice;
        return serialize(
          place,
          isFood ? "food" : activityCategory(place),
          isFood
            ? `Enjoy ${isDateNight ? "a romantic meal" : "a meal"} at ${place.name}.`
            : `A highly rated ${activityCategory(place)} experience for your outing.`,
        );
      }));
    } catch (error) {
      console.error(error);
      return res.status(error.status || 500).json({
        error: error.status ? error.message : "Recommendation service failed.",
      });
    }
  },
);
