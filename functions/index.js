import {initializeApp} from "firebase-admin/app";
import {getAuth} from "firebase-admin/auth";
import {FieldValue, getFirestore} from "firebase-admin/firestore";
import {defineSecret} from "firebase-functions/params";
import {onRequest} from "firebase-functions/v2/https";
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
  Low: ["art gallery", "museum", "bookstore", "casual restaurant"],
  Medium: ["beach", "park", "botanical garden", "walking trail"],
  High: ["basketball court", "fitness activity", "rock climbing", "adventure park"],
};

const freeActivityQueries = {
  Low: [
    "public library",
    "free museum",
    "art gallery",
    "historic site",
    "public garden",
    "bookstore",
  ],
  Medium: [
    "public beach",
    "public park",
    "nature preserve",
    "walking trail",
    "scenic overlook",
    "public garden",
  ],
  High: [
    "public basketball court",
    "hiking trail",
    "public sports field",
    "outdoor fitness park",
    "nature trail",
    "public skate park",
  ],
};

const nearbyActivityFallbackQueries = {
  Low: ["museum", "art gallery", "book store", "tourist attraction"],
  Medium: ["park", "tourist attraction", "museum", "amusement park"],
  High: ["gym", "bowling alley", "amusement park", "hiking area"],
};

const nearbyFoodFallbackQueries = [
  "restaurant",
  "cafe",
  "bakery",
];

const dateEnergyQueries = {
  Low: ["romantic art gallery", "jazz lounge", "scenic overlook", "wine tasting"],
  Medium: ["botanical garden", "live music", "comedy club", "cooking class"],
  High: ["dance class", "kayaking", "rock climbing", "hiking trail"],
};

const dateStyleQueries = {
  Cozy: ["jazz lounge", "bookstore cafe", "wine tasting", "intimate live music"],
  Playful: ["mini golf", "comedy club", "arcade", "dance class"],
  Romantic: ["botanical garden", "scenic overlook", "art gallery", "live music"],
  Adventurous: ["kayaking", "rock climbing", "hiking trail", "adventure tour"],
};

function dateNightTerms(occasion, style, energy) {
  const occasionTerms = {
    "First date": "conversation friendly activity",
    Anniversary: "romantic anniversary experience",
    Surprise: "unique local experience",
    "Regular date": "couples activity",
  };
  return [...new Set([
    occasionTerms[occasion],
    ...(dateStyleQueries[style] || dateStyleQueries.Romantic).slice(0, 2),
    ...(dateEnergyQueries[energy] || dateEnergyQueries.Medium).slice(0, 2),
  ].filter(Boolean))].slice(0, 4);
}

function dateNightFoodTerms(occasion, budget) {
  if (budget === "Free") return ["romantic picnic spot", "scenic picnic area"];
  if (occasion === "First date") {
    return ["conversation friendly restaurant", "cozy cafe"];
  }
  if (occasion === "Anniversary") {
    return ["romantic fine dining restaurant", "special occasion restaurant"];
  }
  if (occasion === "Surprise") {
    return ["unique restaurant", "rooftop restaurant"];
  }
  return ["romantic restaurant", "intimate local restaurant"];
}

function dateNightFallbackTerms(style, energy) {
  const energyTerms = {
    Low: ["museum", "art gallery", "bookstore", "scenic park"],
    Medium: ["botanical garden", "live music", "mini golf", "comedy club"],
    High: ["kayaking", "hiking trail", "dance class", "rock climbing"],
  };
  const styleTerms = {
    Cozy: ["quiet museum", "bookstore", "scenic park"],
    Playful: ["mini golf", "arcade", "comedy club"],
    Romantic: ["botanical garden", "scenic overlook", "art gallery"],
    Adventurous: ["kayaking", "hiking trail", "adventure activity"],
  };
  return [...new Set([
    ...(styleTerms[style] || styleTerms.Romantic),
    ...(energyTerms[energy] || energyTerms.Medium),
  ])].slice(0, 6);
}

function dateNightScore(place, occasion, style) {
  const text = [
    place.name,
    place.matchedQuery,
    ...(place.types || []),
  ].join(" ").toLowerCase();
  const signals = {
    "First date": [
      "conversation",
      "gallery",
      "museum",
      "mini golf",
      "coffee",
      "book",
    ],
    Anniversary: [
      "romantic",
      "scenic",
      "garden",
      "wine",
      "fine dining",
      "special occasion",
    ],
    Surprise: [
      "unique",
      "adventure",
      "comedy",
      "dance",
      "tour",
      "live music",
    ],
    "Regular date": [
      "couples",
      "music",
      "cooking",
      "mini golf",
      "comedy",
    ],
  };
  const styleSignals = {
    Cozy: ["cozy", "jazz", "book", "wine", "intimate"],
    Playful: ["mini golf", "comedy", "arcade", "dance"],
    Romantic: ["romantic", "garden", "scenic", "gallery", "music"],
    Adventurous: ["kayak", "climbing", "hiking", "adventure"],
  };
  let score = rank(place);
  for (const signal of signals[occasion] || []) {
    if (text.includes(signal)) score += 4;
  }
  for (const signal of styleSignals[style] || []) {
    if (text.includes(signal)) score += 3;
  }
  if (occasion === "First date" &&
      (text.includes("night_club") || text.includes("loud"))) {
    score -= 5;
  }
  return score;
}

function dateEventWindow(timing) {
  const now = new Date();
  if (timing === "Tonight") {
    const end = new Date(now);
    end.setUTCHours(24, 0, 0, 0);
    return {start: now, end};
  }
  if (timing === "This weekend") {
    const day = now.getUTCDay();
    const daysUntilSaturday = (6 - day + 7) % 7;
    const start = day === 0 || day === 6 ?
      now :
      new Date(Date.UTC(
        now.getUTCFullYear(),
        now.getUTCMonth(),
        now.getUTCDate() + daysUntilSaturday,
      ));
    const end = new Date(start);
    end.setUTCDate(end.getUTCDate() + (start.getUTCDay() === 0 ? 1 : 2));
    end.setUTCHours(0, 0, 0, 0);
    return {start, end};
  }
  return {
    start: now,
    end: new Date(now.getTime() + 14 * 86400000),
  };
}

function dateEventScore(event, occasion, style) {
  const text = `${event.title} ${event.eventType} ${event.eventGenre}`.toLowerCase();
  const signals = {
    "First date": ["comedy", "arts", "theatre", "music"],
    Anniversary: ["music", "arts", "theatre", "classical"],
    Surprise: ["comedy", "festival", "music", "sports"],
    "Regular date": ["comedy", "music", "sports", "arts"],
    Cozy: ["jazz", "classical", "theatre", "acoustic"],
    Playful: ["comedy", "sports", "festival"],
    Romantic: ["jazz", "classical", "theatre", "music"],
    Adventurous: ["sports", "festival", "outdoor"],
  };
  let score = 0;
  for (const signal of [
    ...(signals[occasion] || []),
    ...(signals[style] || []),
  ]) {
    if (text.includes(signal)) score += 2;
  }
  return score;
}

async function findDateNightEvent({
  apiKey,
  lat,
  lng,
  radiusMiles,
  timing,
  occasion,
  style,
}) {
  try {
    const window = dateEventWindow(timing);
    const events = await searchTicketmasterEvents({
      apiKey,
      lat,
      lng,
      radiusMiles: Math.min(Number(radiusMiles) || 25, 50),
      startDateTime: window.start,
      endDateTime: window.end,
    });
    return events
      .map((event) => ({
        event,
        score: dateEventScore(event, occasion, style),
      }))
      .filter((candidate) => candidate.score >= 2)
      .sort((a, b) => b.score - a.score)[0]?.event || null;
  } catch (error) {
    console.warn("Date Night event search skipped:", error.message);
    return null;
  }
}

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

function placeDistanceMiles(place, lat, lng) {
  const location = place.geometry?.location;
  if (!location || !Number.isFinite(Number(location.lat)) ||
      !Number.isFinite(Number(location.lng))) return Number.POSITIVE_INFINITY;
  return distanceMiles(
    {lat, lng},
    {lat: Number(location.lat), lng: Number(location.lng)},
  );
}

function isWithinRadius(place, lat, lng, radiusMiles) {
  const requestedMiles = Math.max(Number(radiusMiles) || 25, 1);
  // A quarter-mile allowance avoids rejecting places that sit directly on the
  // selected boundary because of coordinate rounding.
  return placeDistanceMiles(place, lat, lng) <= requestedMiles + 0.25;
}

async function searchPlaces(
  apiKey,
  queries,
  lat,
  lng,
  radius,
  hardRadiusMiles = Number(radius) / 1609,
) {
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
  // Legacy Places Text Search treats location/radius as a ranking preference,
  // not a geographic guarantee. Enforce the user's distance choice ourselves
  // so nationally popular matches can never leak into nearby recommendations.
  return uniqueRanked(results.flat())
    .filter((place) => isWithinRadius(place, lat, lng, hardRadiusMiles));
}

async function searchNearbyPlaces(
  apiKey,
  keywords,
  lat,
  lng,
  radius,
  hardRadiusMiles,
) {
  const results = await Promise.all(keywords.map(async (keyword) => {
    const params = new URLSearchParams({
      keyword,
      location: `${lat},${lng}`,
      radius: String(radius),
      key: apiKey,
    });
    const response = await fetch(
      `https://maps.googleapis.com/maps/api/place/nearbysearch/json?${params}`,
    );
    const payload = await response.json();
    if (!response.ok || !["OK", "ZERO_RESULTS"].includes(payload.status)) {
      throw new Error(
        `Google Nearby Places error: ${payload.status || response.status}`,
      );
    }
    return (payload.results || []).map((place) => ({
      ...place,
      matchedQuery: keyword,
    }));
  }));
  return uniqueRanked(results.flat())
    .filter((place) => isWithinRadius(place, lat, lng, hardRadiusMiles));
}

function isFoodPlace(place) {
  const types = new Set(place.types || []);
  return types.has("restaurant") || types.has("cafe") ||
    types.has("bakery") || types.has("meal_takeaway");
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

function activityDiversityKey(place) {
  const types = new Set(place.types || []);
  const groups = [
    ["museum", "museum"],
    ["art_gallery", "art-gallery"],
    ["park", "park"],
    ["natural_feature", "nature"],
    ["aquarium", "aquarium"],
    ["zoo", "zoo"],
    ["amusement_park", "amusement"],
    ["bowling_alley", "bowling"],
    ["movie_theater", "movies"],
    ["night_club", "nightlife"],
    ["spa", "wellness"],
    ["gym", "fitness"],
    ["shopping_mall", "shopping"],
    ["book_store", "books"],
    ["tourist_attraction", "attraction"],
  ];
  for (const [type, key] of groups) {
    if (types.has(type)) return key;
  }
  return activityCategory(place);
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

function companionQueries(event, index, group, budget) {
  const type = String(event.eventType || "");
  if (budget === "Free") {
    return group === "Family" ?
      ["family friendly park", "public library"] :
      ["park", "scenic view"];
  }
  if (group === "Family") {
    return index % 2 === 0 ?
      ["family friendly restaurant", "ice cream shop"] :
      ["park", "mini golf"];
  }
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

async function addEventCompanions(events, apiKey, group, budget) {
  const usedPlaceIds = new Set();
  return Promise.all(events.slice(0, 12).map(async (event, index) => {
    try {
      const candidates = await searchPlaces(
        apiKey,
        companionQueries(event, index, group, budget),
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

function eventSuitability(event, group, budget) {
  const text = `${event.title} ${event.eventType} ${event.eventGenre}`.toLowerCase();
  let score = 0;
  const groupSignals = {
    Family: ["family", "kids", "children", "sports"],
    Couple: ["arts", "theatre", "music", "comedy"],
    Friends: ["sports", "music", "comedy", "festival"],
    Solo: ["arts", "theatre", "museum", "music"],
  };
  for (const signal of groupSignals[group] || []) {
    if (text.includes(signal)) score += 2;
  }

  const minPrice = event.minPrice == null ? Number.NaN : Number(event.minPrice);
  if (budget === "Free") {
    score += Number.isFinite(minPrice) && minPrice === 0 ? 8 : -3;
  } else if (budget === "Under $30") {
    score += Number.isFinite(minPrice) && minPrice <= 30 ? 5 : 0;
  } else if (budget === "$30–$75") {
    score += Number.isFinite(minPrice) && minPrice <= 75 ? 4 : 0;
  } else if (budget === "$75+") {
    score += Number.isFinite(minPrice) && minPrice >= 50 ? 3 : 0;
  }
  return score;
}

function eventDateWindow(body = {}) {
  const pattern = /^\d{4}-\d{2}-\d{2}$/;
  const startText = String(body.startDate || "");
  const endText = String(body.endDate || "");
  const start = pattern.test(startText) ?
    new Date(`${startText}T00:00:00Z`) :
    new Date();
  const requestedEnd = pattern.test(endText) ?
    new Date(`${endText}T00:00:00Z`) :
    new Date(start.getTime() + 13 * 86400000);
  const latestEnd = new Date(start.getTime() + 13 * 86400000);
  const end = requestedEnd > latestEnd ? latestEnd : requestedEnd;
  end.setUTCDate(end.getUTCDate() + 1);
  return {start, end};
}

async function searchEventsWithAdaptiveRadius({
  apiKey,
  lat,
  lng,
  requestedRadius,
  startDateTime,
  endDateTime,
}) {
  const radius = Math.min(Math.max(Number(requestedRadius) || 25, 10), 50);
  const radii = radius <= 10 ? [10, 25, 50] : (radius <= 25 ? [25, 50] : [50]);
  let events = [];
  let searchRadius = radius;
  for (const candidateRadius of radii) {
    searchRadius = candidateRadius;
    events = await searchTicketmasterEvents({
      apiKey,
      lat,
      lng,
      radiusMiles: candidateRadius,
      startDateTime,
      endDateTime,
    });
    if (events.length >= 3) break;
  }
  return events.map((event) => ({
    ...event,
    searchRadiusMiles: searchRadius,
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

function placeDescription(
  place,
  isFood,
  isDateNight,
  index,
  dateOccasion,
  dateStyle,
) {
  const type = readableType(place, isFood);
  const rating = Number(place.rating);
  const reviews = Number(place.user_ratings_total);
  const proof = Number.isFinite(rating) ?
    `${rating.toFixed(1)} stars${reviews > 0 ? ` from ${reviews.toLocaleString("en-US")} reviews` : ""}` :
    "a strong local reputation";

  if (isFood) {
    return isDateNight ?
      `${place.name} brings a ${dateStyle.toLowerCase()} ${type} stop to your ` +
        `${dateOccasion.toLowerCase()}, backed by ${proof}.` :
      `Make ${place.name} the food stop—a ${type} backed by ${proof}.`;
  }

  if (isDateNight) {
    return `${place.name} was chosen for a ${dateStyle.toLowerCase()} ` +
      `${dateOccasion.toLowerCase()}—a ${type} backed by ${proof}.`;
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

async function geocodeTripLocation(apiKey, text) {
  const params = new URLSearchParams({
    address: text,
    key: apiKey,
  });
  const response = await fetch(
    `https://maps.googleapis.com/maps/api/geocode/json?${params}`,
  );
  const data = await response.json();
  const result = data.results?.[0];
  const location = result?.geometry?.location;
  if (!response.ok || data.status !== "OK" || !location) {
    const error = new Error(
      data.status === "ZERO_RESULTS" ?
        `We could not find "${text}". Try a city, address, or landmark.` :
        "Destination lookup failed.",
    );
    error.status = data.status === "ZERO_RESULTS" ? 404 : 502;
    throw error;
  }
  return {
    lat: location.lat,
    lng: location.lng,
    label: result.formatted_address || text,
  };
}

function decodePolyline(encoded) {
  const points = [];
  let index = 0;
  let lat = 0;
  let lng = 0;
  while (index < encoded.length) {
    let result = 0;
    let shift = 0;
    let byte;
    do {
      byte = encoded.charCodeAt(index++) - 63;
      result |= (byte & 0x1f) << shift;
      shift += 5;
    } while (byte >= 0x20 && index <= encoded.length);
    lat += (result & 1) ? ~(result >> 1) : result >> 1;

    result = 0;
    shift = 0;
    do {
      byte = encoded.charCodeAt(index++) - 63;
      result |= (byte & 0x1f) << shift;
      shift += 5;
    } while (byte >= 0x20 && index <= encoded.length);
    lng += (result & 1) ? ~(result >> 1) : result >> 1;
    points.push({lat: lat / 1e5, lng: lng / 1e5});
  }
  return points;
}

function sampleRouteCorridor(points, durationSeconds, intervalMinutes) {
  if (points.length < 3) return [];
  const intervalSeconds = intervalMinutes * 60;
  const requested = Math.max(
    0,
    Math.min(12, Math.floor(durationSeconds / intervalSeconds)),
  );
  const samples = [];
  for (let i = 1; i <= requested; i++) {
    const progress = i / (requested + 1);
    const index = Math.min(
      points.length - 2,
      Math.max(1, Math.round(progress * (points.length - 1))),
    );
    samples.push({...points[index], label: `Route zone ${i}`});
  }
  return samples;
}

async function computeTripRoute(apiKey, origin, destination) {
  const response = await fetch(
    "https://routes.googleapis.com/directions/v2:computeRoutes",
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-Goog-Api-Key": apiKey,
        "X-Goog-FieldMask": [
          "routes.distanceMeters",
          "routes.duration",
          "routes.polyline.encodedPolyline",
        ].join(","),
      },
      body: JSON.stringify({
        origin: {
          location: {
            latLng: {
              latitude: origin.lat,
              longitude: origin.lng,
            },
          },
        },
        destination: {
          location: {
            latLng: {
              latitude: destination.lat,
              longitude: destination.lng,
            },
          },
        },
        travelMode: "DRIVE",
        routingPreference: "TRAFFIC_UNAWARE",
        polylineQuality: "HIGH_QUALITY",
      }),
    },
  );
  const data = await response.json();
  const route = data.routes?.[0];
  if (!response.ok || !route) {
    const error = new Error(
      data.error?.message || "No driving route was found.",
    );
    error.status = response.status === 400 ? 400 : 502;
    throw error;
  }
  const durationSeconds = Number.parseFloat(
    String(route.duration || "0s").replace("s", ""),
  );
  return {
    distanceMeters: Number(route.distanceMeters || 0),
    durationSeconds: Math.round(durationSeconds),
    encodedPolyline: route.polyline?.encodedPolyline || "",
  };
}

export const resolveTripRoute = onRequest(
  {
    region: "us-central1",
    secrets: [GOOGLE_API_KEY, REVENUECAT_SECRET_API_KEY],
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
          error: "Trip Planner+ requires Premium.",
        });
      }

      const originText = String(req.body?.origin || "").trim();
      const destinationText = String(req.body?.destination || "").trim();
      const interval = Number(req.body?.maxTravelMinutesBetweenStops || 120);
      if (!originText || !destinationText ||
          originText.length > 250 || destinationText.length > 250) {
        return res.status(400).json({
          error: "Starting point and destination are required.",
        });
      }
      if (![60, 120, 180].includes(interval)) {
        return res.status(400).json({error: "Choose a valid stop interval."});
      }

      const suppliedLat = Number(req.body?.originLat);
      const suppliedLng = Number(req.body?.originLng);
      const hasSuppliedOrigin =
        Number.isFinite(suppliedLat) && Number.isFinite(suppliedLng);
      const apiKey = GOOGLE_API_KEY.value();
      const [origin, destination] = await Promise.all([
        hasSuppliedOrigin ?
          Promise.resolve({
            lat: suppliedLat,
            lng: suppliedLng,
            label: originText,
          }) :
          geocodeTripLocation(apiKey, originText),
        geocodeTripLocation(apiKey, destinationText),
      ]);
      const route = await computeTripRoute(apiKey, origin, destination);
      const decoded = decodePolyline(route.encodedPolyline);
      return res.json({
        origin,
        destination,
        ...route,
        corridorPoints: sampleRouteCorridor(
          decoded,
          route.durationSeconds,
          interval,
        ),
      });
    } catch (error) {
      console.error(error);
      return res.status(error.status || 502).json({
        error: error.message || "Trip route discovery failed.",
      });
    }
  },
);

function tripDiscoveryQueries(interests = []) {
  const queryByInterest = {
    "Local food": "locally owned restaurant",
    "Scenic stops": "scenic viewpoint",
    History: "historic landmark museum",
    Outdoors: "state park nature attraction",
    "Family fun": "family attraction",
    "Hidden gems": "unique local attraction",
  };
  const selected = interests
    .map((interest) => queryByInterest[String(interest)])
    .filter(Boolean);
  return [...new Set([
    ...selected,
    "popular local attraction",
    "local restaurant",
  ])].slice(0, 3);
}

async function tripPlaceDetails(apiKey, place) {
  try {
    const params = new URLSearchParams({
      place_id: place.place_id,
      fields: "editorial_summary,url,website,photos",
      key: apiKey,
    });
    const response = await fetch(
      `https://maps.googleapis.com/maps/api/place/details/json?${params}`,
    );
    const payload = await response.json();
    if (!response.ok || !["OK", "ZERO_RESULTS"].includes(payload.status)) {
      return place;
    }
    return {...place, ...(payload.result || {})};
  } catch (error) {
    console.warn(`Place details skipped for ${place.place_id}:`, error.message);
    return place;
  }
}

function specificTripPlaceType(place) {
  const labels = {
    aquarium: "aquarium",
    amusement_park: "amusement park",
    art_gallery: "art gallery",
    bakery: "bakery",
    bar: "bar",
    book_store: "bookstore",
    bowling_alley: "bowling alley",
    cafe: "cafe",
    campground: "campground",
    church: "historic church",
    library: "library",
    meal_takeaway: "local food stop",
    movie_theater: "movie theater",
    museum: "museum",
    night_club: "nightlife venue",
    park: "park",
    restaurant: "restaurant",
    shopping_mall: "shopping destination",
    spa: "spa",
    stadium: "stadium",
    tourist_attraction: "visitor attraction",
    zoo: "zoo",
  };
  const type = (place.types || []).find((value) => labels[value]);
  return type ? labels[type] : "local attraction";
}

function tripPlaceDescription(place) {
  const editorial = String(place.editorial_summary?.overview || "").trim();
  if (editorial) return editorial;

  const type = specificTripPlaceType(place);
  const address = String(place.formatted_address || "");
  const location = address.split(",").slice(0, 2).join(",").trim();
  const rating = Number(place.rating);
  const reviews = Number(place.user_ratings_total);
  const proof = Number.isFinite(rating) ?
    ` It is rated ${rating.toFixed(1)} stars` +
      (reviews > 0 ? ` by ${reviews.toLocaleString("en-US")} visitors.` : ".") :
    "";
  return `${place.name} is a ${type}` +
    (location ? ` in ${location}.` : ".") + proof;
}

function excludedTripCandidate(candidate, exclusions) {
  const text = [
    candidate.name,
    candidate.title,
    candidate.matchedQuery,
    ...(candidate.types || []),
  ].filter(Boolean).join(" ").toLowerCase();
  return exclusions.some(
    (exclusion) => text.includes(String(exclusion).toLowerCase()),
  );
}

async function discoverTripZone({
  point,
  index,
  apiKey,
  eventApiKey,
  interests,
  exclusions,
  startsAt,
  endsAt,
  usedIds,
}) {
  const placesPromise = searchPlaces(
    apiKey,
    tripDiscoveryQueries(interests),
    point.lat,
    point.lng,
    milesToMeters(15),
  );
  const eventsPromise = searchTicketmasterEvents({
    apiKey: eventApiKey,
    lat: point.lat,
    lng: point.lng,
    radiusMiles: 20,
    startDateTime: startsAt,
    endDateTime: endsAt,
  }).catch(() => []);

  const [places, events] = await Promise.all([placesPromise, eventsPromise]);
  const candidates = [];
  const event = events.find(
    (item) => !usedIds.has(item.id) &&
      !excludedTripCandidate(item, exclusions),
  );
  if (event) {
    usedIds.add(event.id);
    candidates.push(event);
  }

  for (const place of places) {
    if (candidates.length >= 3) break;
    if (usedIds.has(place.place_id) ||
        excludedTripCandidate(place, exclusions)) {
      continue;
    }
    const category = activityCategory(place);
    if (candidates.some((item) => item.category === category)) continue;
    usedIds.add(place.place_id);
    const detailedPlace = await tripPlaceDetails(apiKey, place);
    candidates.push(
      serialize(
        detailedPlace,
        category,
        tripPlaceDescription(detailedPlace),
      ),
    );
  }

  return {
    index,
    lat: point.lat,
    lng: point.lng,
    candidates,
  };
}

export const discoverTripStops = onRequest(
  {
    region: "us-central1",
    secrets: [
      GOOGLE_API_KEY,
      TICKETMASTER_API_KEY,
      REVENUECAT_SECRET_API_KEY,
    ],
    timeoutSeconds: 120,
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
          error: "Trip Planner+ requires Premium.",
        });
      }

      const rawPoints = Array.isArray(req.body?.corridorPoints) ?
        req.body.corridorPoints :
        [];
      const points = rawPoints.slice(0, 8).map((point) => ({
        lat: Number(point?.lat),
        lng: Number(point?.lng),
      })).filter(
        (point) => Number.isFinite(point.lat) && Number.isFinite(point.lng),
      );
      if (!points.length) {
        return res.status(400).json({
          error: "A route with discovery zones is required.",
        });
      }

      const interests = Array.isArray(req.body?.interests) ?
        req.body.interests.slice(0, 8) :
        [];
      const exclusions = Array.isArray(req.body?.exclusions) ?
        req.body.exclusions.slice(0, 12) :
        [];
      const startsAt = req.body?.startsAt ?
        new Date(req.body.startsAt) :
        new Date();
      const requestedEnd = req.body?.endsAt ?
        new Date(req.body.endsAt) :
        new Date(startsAt.getTime() + 14 * 24 * 60 * 60 * 1000);
      const endsAt = requestedEnd > startsAt ?
        requestedEnd :
        new Date(startsAt.getTime() + 14 * 24 * 60 * 60 * 1000);
      const usedIds = new Set();
      const zones = [];
      for (let index = 0; index < points.length; index++) {
        zones.push(await discoverTripZone({
          point: points[index],
          index,
          apiKey: GOOGLE_API_KEY.value(),
          eventApiKey: TICKETMASTER_API_KEY.value(),
          interests,
          exclusions,
          startsAt,
          endsAt,
          usedIds,
        }));
      }
      return res.json(zones);
    } catch (error) {
      console.error(error);
      return res.status(502).json({
        error: error.message || "Trip discovery failed.",
      });
    }
  },
);

export const getIdeas = onRequest(
  {
    region: "us-central1",
    secrets: [
      GOOGLE_API_KEY,
      REVENUECAT_SECRET_API_KEY,
      TICKETMASTER_API_KEY,
    ],
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
      const dateOccasion = String(req.body?.dateOccasion || "Regular date");
      const dateStyle = String(req.body?.dateStyle || "Romantic");
      const dateTiming = String(req.body?.dateTiming || "Tonight");
      const radiusMiles = Number(req.body?.radius) || 25;
      const radius = milesToMeters(radiusMiles);
      const googleKey = GOOGLE_API_KEY.value();

      const foodTerms = isDateNight
        ? dateNightFoodTerms(dateOccasion, budget)
        : (foodQueries[budget] || foodQueries["$"]);
      const experienceTerms = isDateNight ?
        dateNightTerms(dateOccasion, dateStyle, energy) :
        (budget === "Free" ?
          (freeActivityQueries[energy] || freeActivityQueries.Medium) :
          (activityQueries[energy] || activityQueries.Medium))
          .map((term) => group === "Family" ? `family friendly ${term}` : term);

      const [initialFoodResults, initialExperienceResults, recentIds, dateEvent] =
        await Promise.all([
        searchPlaces(googleKey, foodTerms, lat, lng, radius, radiusMiles),
        searchPlaces(
          googleKey,
          experienceTerms,
          lat,
          lng,
          radius,
          radiusMiles,
        ),
        recentRecommendationIds(user.uid),
        isDateNight ?
          findDateNightEvent({
            apiKey: TICKETMASTER_API_KEY.value(),
            lat,
            lng,
            radiusMiles,
            timing: dateTiming,
            occasion: dateOccasion,
            style: dateStyle,
          }) :
          Promise.resolve(null),
      ]);

      let foodResults = initialFoodResults;
      let experienceResults = initialExperienceResults
        .filter((place) => !isFoodPlace(place));
      const requiredExperienceCount = budget === "Free" ? 4 : 3;
      if (isDateNight && experienceResults.length < requiredExperienceCount) {
        const fallbackResults = await searchPlaces(
          googleKey,
          dateNightFallbackTerms(dateStyle, energy),
          lat,
          lng,
          radius,
          radiusMiles,
        );
        experienceResults = uniqueRanked([
          ...experienceResults,
          ...fallbackResults,
        ]).filter((place) => !isFoodPlace(place));
      }

      // Text Search uses location as a ranking preference and can be sparse for
      // tightly constrained requests. Nearby Search supplies a broader local
      // pool while the hard distance filter above still guarantees the user's
      // selected radius.
      if (budget !== "Free" &&
          foodResults.filter((place) => priceAllowed(place, budget)).length < 1) {
        const nearbyFood = await searchNearbyPlaces(
          googleKey,
          nearbyFoodFallbackQueries,
          lat,
          lng,
          radius,
          radiusMiles,
        );
        foodResults = uniqueRanked([...foodResults, ...nearbyFood]);
      }
      if (experienceResults.length < requiredExperienceCount) {
        const nearbyExperiences = await searchNearbyPlaces(
          googleKey,
          nearbyActivityFallbackQueries[energy] ||
            nearbyActivityFallbackQueries.Medium,
          lat,
          lng,
          radius,
          radiusMiles,
        );
        experienceResults = uniqueRanked([
          ...experienceResults,
          ...nearbyExperiences,
        ]).filter((place) => !isFoodPlace(place));
      }

      const eligibleFood = foodResults
        .filter((place) => priceAllowed(place, budget));
      const unseenFood = eligibleFood
        .filter((place) => !recentIds.has(place.place_id));
      const unseenExperiences = experienceResults
        .filter((place) => !recentIds.has(place.place_id));
      // Prefer fresh recommendations, but do not fail a small-radius request
      // merely because fewer than four unseen places remain. Top up from the
      // verified in-radius pool while keeping unseen places first.
      const food = [
        ...unseenFood,
        ...eligibleFood.filter(
          (place) => !unseenFood.some(
            (unseen) => unseen.place_id === place.place_id,
          ),
        ),
      ];
      let experiences = [
        ...unseenExperiences,
        ...experienceResults.filter(
          (place) => !unseenExperiences.some(
            (unseen) => unseen.place_id === place.place_id,
          ),
        ),
      ];
      const eligibleDateEvent = dateEvent && !recentIds.has(dateEvent.id) &&
          distanceMiles(
            {lat, lng},
            {lat: Number(dateEvent.lat), lng: Number(dateEvent.lng)},
          ) <= radiusMiles + 0.25 ?
        dateEvent :
        null;
      if (isDateNight) {
        experiences = [...experiences].sort(
          (a, b) =>
            dateNightScore(b, dateOccasion, dateStyle) -
            dateNightScore(a, dateOccasion, dateStyle),
        );
      }

      const selectedExperiences = [];
      for (const place of experiences) {
        if (selectedExperiences.length === 3) break;
        const duplicateCategory = selectedExperiences.some(
          (selected) =>
            activityDiversityKey(selected) === activityDiversityKey(place),
        );
        if (!duplicateCategory) {
          selectedExperiences.push(place);
        }
      }
      for (const place of experiences) {
        if (selectedExperiences.length === 3) break;
        if (!selectedExperiences.includes(place)) selectedExperiences.push(place);
      }

      const foodChoice = budget === "Free" ? null : food[0];
      const selected = foodChoice ?
        (isDateNight ?
          [
            eligibleDateEvent || selectedExperiences[0],
            foodChoice,
            ...selectedExperiences.slice(
              eligibleDateEvent ? 0 : 1,
              eligibleDateEvent ? 2 : 3,
            ),
          ] :
          [foodChoice, ...selectedExperiences.slice(0, 3)]) :
        (eligibleDateEvent ?
          [eligibleDateEvent, ...experiences.slice(0, 3)] :
          experiences.slice(0, 4));

      if (selected.length < 4) {
        console.warn("Recommendation pool too small", {
          radiusMiles,
          budget,
          energy,
          group,
          isDateNight,
          foodCandidates: eligibleFood.length,
          experienceCandidates: experienceResults.length,
          selected: selected.length,
        });
        return res.status(404).json({
          error: "We could not find four strong, different options nearby.",
        });
      }

      const selectedWithPhotos = await Promise.all(selected.map((place) => {
        if (place.category === "event" || place.photos?.length) return place;
        return tripPlaceDetails(googleKey, place);
      }));

      if (!premium) await consumeFreeRequest(user.uid);
      await rememberRecommendations(
        user.uid,
        selectedWithPhotos.map((place) => place.place_id || place.id),
      );

      return res.json(selectedWithPhotos.map((place, index) => {
        if (place.category === "event") return place;
        const isFood = place.place_id === foodChoice?.place_id;
        return serialize(
          place,
          isFood ? "food" : activityCategory(place),
          placeDescription(
            place,
            isFood,
            isDateNight,
            index,
            dateOccasion,
            dateStyle,
          ),
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

      const window = eventDateWindow(req.body);
      const group = String(req.body?.group || "Friends");
      const budget = String(req.body?.budget || "$30–$75");
      const events = await searchEventsWithAdaptiveRadius({
        apiKey: TICKETMASTER_API_KEY.value(),
        lat,
        lng,
        requestedRadius: req.body?.radius,
        startDateTime: window.start,
        endDateTime: window.end,
      });
      events.sort(
        (a, b) =>
          eventSuitability(b, group, budget) -
          eventSuitability(a, group, budget),
      );
      const plannedEvents = await addEventCompanions(
        events,
        GOOGLE_API_KEY.value(),
        group,
        budget,
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
      const requestedUrl = String(req.query.url || "").trim();
      if (!requestedUrl) {
        return res.status(400).send("A valid event image URL is required.");
      }
      const source = new URL(requestedUrl);
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

      const image = Buffer.from(await response.arrayBuffer());
      res.set("Access-Control-Allow-Origin", "*");
      res.set("Content-Type", contentType);
      res.set("Cache-Control", "public, max-age=86400");
      return res.status(200).send(image);
    } catch (error) {
      console.error(error);
      if (error instanceof TypeError) {
        return res.status(400).send("A valid event image URL is required.");
      }
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
      return res.json({allowed, testerId: user.uid});
    } catch (error) {
      console.error(error);
      return res.status(500).json({error: "Access check failed."});
    }
  },
);


