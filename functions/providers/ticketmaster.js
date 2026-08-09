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

function firstExternalUrl(externalLinks = {}) {
  for (const key of ["homepage", "wiki", "facebook", "instagram"]) {
    const value = externalLinks[key]?.find((link) => link?.url)?.url;
    if (value) return value;
  }
  return null;
}

function eventInfoUrl(event, venue) {
  const attraction = event._embedded?.attractions?.[0] || {};
  const officialUrl = firstExternalUrl(attraction.externalLinks) ||
    firstExternalUrl(venue.externalLinks);
  if (officialUrl) return officialUrl;

  const query = [event.name, venue.name, venue.city?.name, "event information"]
    .filter(Boolean)
    .join(" ");
  return `https://www.google.com/search?q=${encodeURIComponent(query)}`;
}

function normalizeEvent(event) {
  const venue = event._embedded?.venues?.[0] || {};
  const classification = event.classifications?.[0] || {};
  const priceRange = event.priceRanges?.[0] || {};
  const lat = Number(venue.location?.latitude);
  const lng = Number(venue.location?.longitude);

  if (!event.id || !event.name || !Number.isFinite(lat) ||
      !Number.isFinite(lng)) {
    return null;
  }

  return {
    id: `ticketmaster:${event.id}`,
    category: "event",
    eventType:
      classification.segment?.name?.toLowerCase() || "event",
    eventGenre: classification.genre?.name?.toLowerCase() || null,
    title: event.name,
    description: eventDescription(event, venue),
    address: eventAddress(venue),
    lat,
    lng,
    photoUrl: eventImage(event.images),
    eventUrl: event.url || null,
    infoUrl: eventInfoUrl(event, venue),
    eventStart: event.dates?.start?.dateTime || null,
    eventLocalDate: event.dates?.start?.localDate || null,
    eventLocalTime: event.dates?.start?.localTime || null,
    venueName: venue.name || null,
    source: "ticketmaster",
    minPrice: Number.isFinite(Number(priceRange.min)) ?
      Number(priceRange.min) :
      null,
    maxPrice: Number.isFinite(Number(priceRange.max)) ?
      Number(priceRange.max) :
      null,
    priceCurrency: priceRange.currency || null,
  };
}

export async function searchTicketmasterEvents({
  apiKey,
  lat,
  lng,
  radiusMiles,
  startDateTime = new Date(),
  endDateTime,
}) {
  const end = endDateTime || new Date(
    startDateTime.getTime() + 14 * 24 * 60 * 60 * 1000,
  );

  const params = new URLSearchParams({
    apikey: apiKey,
    latlong: `${lat},${lng}`,
    radius: String(Math.min(Math.max(Number(radiusMiles) || 25, 1), 500)),
    unit: "miles",
    startDateTime: isoWithoutMilliseconds(startDateTime),
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

