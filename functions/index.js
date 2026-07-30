import {initializeApp} from "firebase-admin/app";
import {getAuth} from "firebase-admin/auth";
import {FieldValue, getFirestore} from "firebase-admin/firestore";
import {defineSecret} from "firebase-functions/params";
import {onRequest} from "firebase-functions/v2/https";
import fetch from "node-fetch";
import {searchTicketmasterEvents} from "./providers/ticketmaster.js";

initializeApp();

const GOOGLE_API_KEY = defineSecret("GOOGLE_API_KEY");
const REVENUECAT_SECRET_API_KEY = defineSecret("REVENUECAT_SECRET_API_KEY");
const TICKETMASTER_API_KEY = defineSecret("TICKETMASTER_API_KEY");
const FREE_WEEKLY_LIMIT = 3;
const PHOTO_PROXY_URL =
  "https://us-central1-decide-for-us-792bc.cloudfunctions.net/getPlacePhoto";

const foodQueries = {
  Free: ["affordable restaurant", "casual restaurant"],
  "Under $30": ["affordable restaurant", "casual restaurant"],
  "$30–$75": ["casual restaurant", "local restaurant"],
  "$75+": ["upscale restaurant", "fine dining restaurant"],
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
  if (budget === "Under $30" || budget === "$") {
    return place.price_level == null || place.price_level <= 1;
  }
  if (budget === "$30–$75" || budget === "$$") {
    return place.price_level == null || place.price_level <= 2;
  }
  if (budget === "$75+") {
    return place.price_level == null || place.price_level <= 4;
  }
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
    return (payload.results || []).map((place) => ({
      ...place,
      matchedQuery: query,
    }));
  }));
  return uniqueRanked(results.flat());
}

function activityCategory(place) {
  const types = new Set(place.types || []);
  if (types.has("restaurant") || types.has("cafe") ||
      types.has("bakery") || types.has("meal_takeaway")) return "food";
  if (types.has("museum") || types.has("art_gallery")) return "culture";
  if (types.has("park") || types.has("natural_feature")) return "outdoors";
  if (types.has("movie_theater") || types.has("night_club")) return "entertainment";
  return "experience";
}

function serialize(place, category, description) {
  const photoReference = place.photos?.[0]?.photo_reference;
  return {
    id: place.place_id,
    category,
    title: place.name,
    description,
    address: place.formatted_address || "",
    lat: place.geometry.location.lat,
    lng: place.geometry.location.lng,
    photoUrl: photoReference ?
      `${PHOTO_PROXY_URL}?ref=${encodeURIComponent(photoReference)}` :
      null,
  };
}

function distanceMiles(first, second) {
  const radians = (degrees) => degrees * Math.PI / 180;
  const latDelta = radians(second.lat - first.lat);
  const lngDelta = radians(second.lng - first.lng);
  const a = Math.sin(latDelta / 2) ** 2 +
    Math.cos(radians(first.lat)) * Math.cos(radians(second.lat)) *
    Math.sin(lngDelta / 2) ** 2;
  return 3959 * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

function companionQueries(event, index) {
  const type = String(event.eventType || "");
  if (type.includes("sports")) {
    return index % 2 === 0 ?
      ["local restaurant", "dessert shop"] :
      ["bowling alley", "arcade"];
  }
  if (type.includes("arts") || type.includes("theatre")) {
    return index % 2 === 0 ?
      ["coffee shop", "dessert shop"] :
      ["art gallery", "bookstore"];
  }
  if (type.includes("family")) {
    return index % 2 === 0 ?
      ["ice cream shop", "casual restaurant"] :
      ["park", "mini golf"];
  }
  return index % 2 === 0 ?
    ["local restaurant", "dessert shop"] :
    ["scenic view", "art gallery"];
}

async function addEventCompanions(events, apiKey) {
  const usedPlaceIds = new Set();
  return Promise.all(events.slice(0, 12).map(async (event, index) => {
    try {
      const candidates = await searchPlaces(
        apiKey,
        companionQueries(event, index),
        event.lat,
        event.lng,
        milesToMeters(5),
      );
      const available = candidates.filter(
        (place) => !usedPlaceIds.has(place.place_id),
      );
      const place = available
        .map((candidate) => ({
          ...candidate,
          distance: distanceMiles(
            {lat: event.lat, lng: event.lng},
            {
              lat: candidate.geometry.location.lat,
              lng: candidate.geometry.location.lng,
            },
          ),
        }))
        .filter((candidate) => candidate.distance <= 5)
        .sort((a, b) => a.distance - b.distance || rank(b) - rank(a))[0];
      if (!place) return event;

      usedPlaceIds.add(place.place_id);
      return {
        ...event,
        companion: serialize(
          place,
          activityCategory(place),
          `${place.name} is a nearby add-on, about ` +
            `${place.distance.toFixed(1)} miles from the event.`,
        ),
        companionDistanceMiles: Number(place.distance.toFixed(1)),
      };
    } catch (error) {
      console.warn(`Could not pair event ${event.id}:`, error.message);
      return event;
    }
  }));
}

function readableType(place, isFood) {
  const matched = String(place.matchedQuery || "")
    .replace(/^family friendly /, "")
    .replace(/^romantic /, "")
    .trim();
  if (matched) return matched;

  const labels = {
    art_gallery: "art gallery",
    bowling_alley: "bowling experience",
    book_store: "bookstore",
    campground: "outdoor escape",
    museum: "museum",
    movie_theater: "movie experience",
    night_club: "nightlife spot",
    park: "park",
    restaurant: "restaurant",
    tourist_attraction: "local attraction",
  };
  const type = (place.types || []).find((value) => labels[value]);
  return type ? labels[type] : (isFood ? "restaurant" : "local experience");
}

function placeDescription(place, isFood, isDateNight, index) {
  const type = readableType(place, isFood);
  const rating = Number(place.rating);
  const reviews = Number(place.user_ratings_total);
  const proof = Number.isFinite(rating) ?
    `${rating.toFixed(1)} stars${reviews > 0 ? ` from ${reviews.toLocaleString("en-US")} reviews` : ""}` :
    "a strong local reputation";

  if (isFood) {
    return isDateNight ?
      `${place.name} brings a ${type} stop to the date, backed by ${proof}.` :
      `Make ${place.name} the food stop—a ${type} backed by ${proof}.`;
  }

  const templates = [
    `Start with ${place.name}, a ${type} chosen for its ${proof}.`,
    `${place.name} adds a ${type} to the plan and carries ${proof}.`,
    `For a different kind of outing, explore ${place.name}—a ${type} with ${proof}.`,
    `Round out this option at ${place.name}, a ${type} earning ${proof}.`,
  ];
  return templates[index % templates.length];
}

async function recentRecommendationIds(uid) {
  const snapshot = await getFirestore().collection("recommendation_history")
    .doc(uid).get();
  return new Set(snapshot.data()?.recentIds || []);
}

async function rememberRecommendations(uid, ids) {
  const reference = getFirestore().collection("recommendation_history").doc(uid);
  const snapshot = await reference.get();
  const previous = snapshot.data()?.recentIds || [];
  const recentIds = [...new Set([...ids, ...previous])].slice(0, 40);
  await reference.set({
    recentIds,
    updatedAt: FieldValue.serverTimestamp(),
  }, {merge: true});
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

async function hasTesterAccess(uid) {
  const snapshot = await getFirestore().collection("premium_testers")
    .doc(uid).get();
  return snapshot.data()?.enabled === true;
}

async function hasPremiumAccess(uid, apiKey) {
  const [premium, tester] = await Promise.all([
    hasPremium(uid, apiKey),
    hasTesterAccess(uid),
  ]);
  return premium || tester;
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

      const premium = await hasPremiumAccess(
        user.uid,
        REVENUECAT_SECRET_API_KEY.value(),
      );
      const isDateNight = req.body?.isDateNight === true;
      if (isDateNight && !premium) {
        return res.status(403).json({error: "Date Night+ requires Premium."});
      }
      const lat = Number(req.body?.lat);
      const lng = Number(req.body?.lng);
      if (!Number.isFinite(lat) || !Number.isFinite(lng)) {
        return res.status(400).json({error: "A valid location is required."});
      }

      const budget = req.body?.budget || "$30–$75";
      const energy = req.body?.energy || "Medium";
      const group = req.body?.group || "Couple";
      const radius = milesToMeters(req.body?.radius);
      const googleKey = GOOGLE_API_KEY.value();

      const foodTerms = isDateNight
        ? ["romantic restaurant", "fine dining restaurant"]
        : (foodQueries[budget] || foodQueries["$"]);
      const coupleTerms = [
        "bowling alley",
        "mini golf",
        "museum",
        "local attraction",
      ];
      const experienceTerms = isDateNight ?
        ["romantic activity", "live music", "scenic view", "art gallery"] :
        (group === "Couple" ?
          coupleTerms :
          (activityQueries[energy] || activityQueries.Medium)
            .map((term) => group === "Family" ? `family friendly ${term}` : term));

      const [foodResults, experienceResults, recentIds] = await Promise.all([
        searchPlaces(googleKey, foodTerms, lat, lng, radius),
        searchPlaces(googleKey, experienceTerms, lat, lng, radius),
        recentRecommendationIds(user.uid),
      ]);

      const unseenFood = foodResults
        .filter((place) => !recentIds.has(place.place_id))
        .filter((place) => priceAllowed(place, budget));
      const unseenExperiences = experienceResults
        .filter((place) => !recentIds.has(place.place_id));
      const food = unseenFood.length ? unseenFood : foodResults;
      const experiences = unseenExperiences.length ?
        unseenExperiences :
        experienceResults;

      const selectedExperiences = [];
      for (const place of experiences) {
        if (selectedExperiences.length === 3) break;
        const duplicateCategory = selectedExperiences.some(
          (selected) =>
            activityCategory(selected) === activityCategory(place),
        );
        if (!duplicateCategory || selectedExperiences.length >= 2) {
          selectedExperiences.push(place);
        }
      }
      for (const place of experiences) {
        if (selectedExperiences.length === 3) break;
        if (!selectedExperiences.includes(place)) selectedExperiences.push(place);
      }

      const foodChoice = budget === "Free" ? null : food[0];
      const selected = foodChoice ?
        [foodChoice, ...selectedExperiences.slice(0, 3)] :
        experiences.slice(0, 4);

      if (selected.length < 4) {
        return res.status(404).json({
          error: "We could not find four strong, different options nearby.",
        });
      }

      if (!premium) await consumeFreeRequest(user.uid);
      await rememberRecommendations(
        user.uid,
        selected.map((place) => place.place_id),
      );

      return res.json(selected.map((place, index) => {
        const isFood = place === foodChoice;
        return serialize(
          place,
          isFood ? "food" : activityCategory(place),
          placeDescription(place, isFood, isDateNight, index),
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

export const getPlacePhoto = onRequest(
  {
    region: "us-central1",
    secrets: [GOOGLE_API_KEY],
  },
  async (req, res) => {
    res.set("Access-Control-Allow-Origin", "*");
    res.set("Access-Control-Allow-Methods", "GET, OPTIONS");
    if (req.method === "OPTIONS") return res.status(204).send("");
    const reference = String(req.query.ref || "");
    if (!reference || reference.length > 2000) {
      return res.status(400).send("A valid photo reference is required.");
    }

    try {
      const params = new URLSearchParams({
        maxwidth: "1200",
        photo_reference: reference,
        key: GOOGLE_API_KEY.value(),
      });
      const response = await fetch(
        `https://maps.googleapis.com/maps/api/place/photo?${params}`,
      );
      if (!response.ok) {
        return res.status(response.status).send("Photo unavailable.");
      }

      const contentType = response.headers.get("content-type") || "image/jpeg";
      const image = await response.buffer();
      res.set("Content-Type", contentType);
      res.set("Cache-Control", "public, max-age=86400");
      return res.status(200).send(image);
    } catch (error) {
      console.error(error);
      return res.status(502).send("Photo unavailable.");
    }
  },
);

export const getLocalEvents = onRequest(
  {
    region: "us-central1",
    secrets: [
      TICKETMASTER_API_KEY,
      REVENUECAT_SECRET_API_KEY,
      GOOGLE_API_KEY,
    ],
  },
  async (req, res) => {
    res.set("Access-Control-Allow-Origin", "*");
    res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
    res.set("Access-Control-Allow-Headers", "Authorization, Content-Type");
    if (req.method === "OPTIONS") return res.status(204).send("");
    if (req.method !== "POST") {
      return res.status(405).json({error: "POST required."});
    }

    try {
      const user = await authenticatedUser(req);
      if (!user) {
        return res.status(401).json({error: "Authentication required."});
      }

      const premium = await hasPremiumAccess(
        user.uid,
        REVENUECAT_SECRET_API_KEY.value(),
      );
      if (!premium) {
        return res.status(403).json({
          error: "Local Events+ requires Premium.",
        });
      }

      const lat = Number(req.body?.lat);
      const lng = Number(req.body?.lng);
      if (!Number.isFinite(lat) || !Number.isFinite(lng)) {
        return res.status(400).json({error: "A valid location is required."});
      }

      const events = await searchTicketmasterEvents({
        apiKey: TICKETMASTER_API_KEY.value(),
        lat,
        lng,
        radiusMiles: req.body?.radius,
      });
      const plannedEvents = await addEventCompanions(
        events,
        GOOGLE_API_KEY.value(),
      );
      return res.json(plannedEvents);
    } catch (error) {
      console.error(error);
      return res.status(502).json({error: "Local event search failed."});
    }
  },
);

export const getEventImage = onRequest(
  {region: "us-central1"},
  async (req, res) => {
    try {
      const source = new URL(String(req.query.url || ""));
      const host = source.hostname.toLowerCase();
      const allowed = host === "ticketm.net" ||
        host.endsWith(".ticketm.net") ||
        host === "tmol.io" ||
        host.endsWith(".tmol.io");
      if (source.protocol !== "https:" || !allowed) {
        return res.status(400).send("A valid event image URL is required.");
      }

      const response = await fetch(source);
      if (!response.ok) {
        return res.status(response.status).send("Event image unavailable.");
      }

      const contentType = response.headers.get("content-type") || "";
      if (!contentType.startsWith("image/")) {
        return res.status(415).send("Event image unavailable.");
      }

      const image = await response.buffer();
      res.set("Access-Control-Allow-Origin", "*");
      res.set("Content-Type", contentType);
      res.set("Cache-Control", "public, max-age=86400");
      return res.status(200).send(image);
    } catch (error) {
      console.error(error);
      return res.status(502).send("Event image unavailable.");
    }
  },
);

export const getPremiumAccess = onRequest(
  {
    region: "us-central1",
    secrets: [REVENUECAT_SECRET_API_KEY],
  },
  async (req, res) => {
    res.set("Access-Control-Allow-Origin", "*");
    res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
    res.set("Access-Control-Allow-Headers", "Authorization, Content-Type");
    if (req.method === "OPTIONS") return res.status(204).send("");
    if (req.method !== "POST") {
      return res.status(405).json({error: "POST required."});
    }

    try {
      const user = await authenticatedUser(req);
      if (!user) {
        return res.status(401).json({error: "Authentication required."});
      }
      const allowed = await hasPremiumAccess(
        user.uid,
        REVENUECAT_SECRET_API_KEY.value(),
      );
      return res.json({allowed});
    } catch (error) {
      console.error(error);
      return res.status(500).json({error: "Access check failed."});
    }
  },
);

