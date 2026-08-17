from pathlib import Path

path = Path('functions/index.js')
raw = path.read_bytes()
newline = b'\r\n' if b'\r\n' in raw else b'\n'
text = raw.decode('utf-8').replace('\r\n','\n')

old = '''async function searchPlaces(apiKey, queries, lat, lng, radius) {
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
'''

new = '''async function searchPlaces(apiKey, queries, lat, lng, radius, maxDistanceMiles) {
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
  const ranked = uniqueRanked(results.flat());
  if (!Number.isFinite(Number(maxDistanceMiles))) return ranked;
  const origin = {lat: Number(lat), lng: Number(lng)};
  return ranked.filter((place) => {
    const location = place.geometry?.location;
    if (!location || !Number.isFinite(Number(location.lat)) ||
        !Number.isFinite(Number(location.lng))) return false;
    return distanceMiles(origin, {
      lat: Number(location.lat),
      lng: Number(location.lng),
    }) <= Number(maxDistanceMiles);
  });
}
'''

if old not in text:
    raise SystemExit('searchPlaces block not found')
text = text.replace(old, new, 1)

old2 = '''        searchPlaces(googleKey, foodTerms, lat, lng, radius),
        searchPlaces(googleKey, experienceTerms, lat, lng, radius),'''
new2 = '''        searchPlaces(googleKey, foodTerms, lat, lng, radius, radiusMiles),
        searchPlaces(googleKey, experienceTerms, lat, lng, radius, radiusMiles),'''
if old2 not in text:
    raise SystemExit('getIdeas search calls not found')
text = text.replace(old2, new2, 1)

out = text.replace('\n','\r\n') if newline == b'\r\n' else text
path.write_bytes(out.encode('utf-8'))
