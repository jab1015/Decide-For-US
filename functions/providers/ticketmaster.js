import fetch from "node-fetch";

const API_URL = "https://app.ticketmaster.com/discovery/v2/events.json";
const IMAGE_PROXY_URL =
  "https://us-central1-decide-for-us-792bc.cloudfunctions.net/getEventImage";

function isoWithoutMilliseconds(date) {
  return date.toISOString().replace(/\.\d{3}Z$/, "Z");
}

function eventImage(images = []) {
  const source = [...images]
    .filter((image) => image?.url)
    .sort((a, b) => (b.width || 0) - (a.width || 0))[0]?.url;
  return source ?
    `${IMAGE_PROXY_URL}?url=${encodeURIComponent(source)}` :
    null;
}

function eventAddress(venue = {}) {
  return [
    venue.address?.line1,
    venue.city?.name,
    venue.state?.stateCode || venue.state?.name,
    venue.postalCode,
  ].filter(Boolean).join(", ");
}

function eventDescription(event, venue) {
  const category = event.classifications?.[0]?.segment?.name || "Live event";
  const venueName = venue.name || "a local venue";
  const localDate = event.dates?.start?.localDate;
  const localTime = event.dates?.start?.localTime;
  const when = [localDate, localTime].filter(Boolean).join(" at ");
  return `${category} at ${venueName}${when ? ` on ${when}` : ""}.`;
}

function normalizeEvent(event) {
  const venue = event._embedded?.venues?.[0] || {};
  const lat = Number(venue.location?.latitude);
  const lng = Number(venue.location?.longitude);

  if (!event.id || !event.name || !Number.isFinite(lat) ||
      !Number.isFinite(lng)) {
    return null;
  }

  return {
    id: `ticketmaster:${event.id}`,
    category: "event",
    title: event.name,
    description: eventDescription(event, venue),
    address: eventAddress(venue),
    lat,
    lng,
    photoUrl: eventImage(event.images),
    eventUrl: event.url || null,
    eventStart: event.dates?.start?.dateTime || null,
    eventLocalDate: event.dates?.start?.localDate || null,
    eventLocalTime: event.dates?.start?.localTime || null,
    venueName: venue.name || null,
    source: "ticketmaster",
  };
}

export async function searchTicketmasterEvents({
  apiKey,
  lat,
  lng,
  radiusMiles,
  daysAhead = 14,
}) {
  const end = new Date();
  end.setUTCDate(end.getUTCDate() + daysAhead);

  const params = new URLSearchParams({
    apikey: apiKey,
    latlong: `${lat},${lng}`,
    radius: String(Math.min(Math.max(Number(radiusMiles) || 25, 1), 500)),
    unit: "miles",
    startDateTime: isoWithoutMilliseconds(new Date()),
    endDateTime: isoWithoutMilliseconds(end),
    includeTBA: "no",
    size: "40",
    sort: "date,asc",
  });

  const response = await fetch(`${API_URL}?${params}`);
  const payload = await response.json();
  if (!response.ok) {
    throw new Error(
      `Ticketmaster error: ${payload.fault?.faultstring || response.status}`,
    );
  }

  return (payload._embedded?.events || [])
    .map(normalizeEvent)
    .filter(Boolean);
}
