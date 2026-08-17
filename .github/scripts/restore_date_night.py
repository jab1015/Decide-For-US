from pathlib import Path


def must_replace(text, old, new, label):
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"{label}: expected exactly 1 match, found {count}")
    return text.replace(old, new, 1)


screen_path = Path("lib/screens/decide_screen.dart")
screen = screen_path.read_text(encoding="utf-8")

screen = must_replace(
    screen,
    "  String? selectedEnergy;\n  String? _groupBeforeDateNight;",
    "  String? selectedEnergy;\n  String? selectedDateOccasion;\n  String? selectedDateStyle;\n  String? selectedDateTiming;\n  String? _groupBeforeDateNight;",
    "Date Night state",
)
screen = must_replace(
    screen,
    "    isDateNight = false;\n    _groupBeforeDateNight = null;\n  }",
    "    isDateNight = false;\n    _groupBeforeDateNight = null;\n    selectedDateOccasion = null;\n    selectedDateStyle = null;\n    selectedDateTiming = null;\n  }",
    "Date Night reset",
)
screen = must_replace(
    screen,
    "          radiusMiles: selectedRadius,\n        ),",
    "          radiusMiles: selectedRadius,\n          dateOccasion: selectedDateOccasion,\n          dateStyle: selectedDateStyle,\n          dateTiming: selectedDateTiming,\n        ),",
    "Date Night request fields",
)
screen = must_replace(
    screen,
    "        selectedGroup = _groupBeforeDateNight;\n        _groupBeforeDateNight = null;\n      });",
    "        selectedGroup = _groupBeforeDateNight;\n        _groupBeforeDateNight = null;\n        selectedDateOccasion = null;\n        selectedDateStyle = null;\n        selectedDateTiming = null;\n      });",
    "Date Night disable reset",
)
screen = must_replace(
    screen,
    "        _groupBeforeDateNight = selectedGroup;\n        selectedGroup = 'Couple';\n        isDateNight = true;",
    "        _groupBeforeDateNight = selectedGroup;\n        selectedGroup = 'Couple';\n        selectedDateOccasion = 'Regular date';\n        selectedDateStyle = 'Romantic';\n        selectedDateTiming = 'Tonight';\n        isDateNight = true;",
    "Date Night defaults",
)
screen = must_replace(
    screen,
    """            if (isDateNight)
              const Text(
                'Date Night+ is planned for two.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            const SizedBox(height: 20),
            sectionLabel(\"Total outing budget\"),""",
    """            if (isDateNight) ...[
              const Text(
                'Date Night+ is planned for two.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              sectionLabel(\"What’s the occasion?\"),
              row(
                [\"First date\", \"Regular date\", \"Anniversary\", \"Surprise\"],
                selectedDateOccasion,
                (v) => selectedDateOccasion = v,
              ),
              const SizedBox(height: 16),
              sectionLabel(\"What kind of date?\"),
              row(
                [\"Cozy\", \"Playful\", \"Romantic\", \"Adventurous\"],
                selectedDateStyle,
                (v) => selectedDateStyle = v,
              ),
              const SizedBox(height: 16),
              sectionLabel(\"When?\"),
              row(
                [\"Tonight\", \"This weekend\", \"Plan ahead\"],
                selectedDateTiming,
                (v) => selectedDateTiming = v,
              ),
            ],
            const SizedBox(height: 20),
            sectionLabel(\"Total outing budget\"),""",
    "Date Night controls",
)
screen_path.write_text(screen, encoding="utf-8")

backend_path = Path("functions/index.js")
backend = backend_path.read_text(encoding="utf-8")

old_queries = '''const dateNightActivityQueries = {
  Low: ["romantic art gallery", "jazz lounge", "scenic overlook", "wine tasting"],
  Medium: ["botanical garden", "live music", "comedy club", "cooking class"],
  High: ["dance class", "kayaking", "rock climbing", "hiking trail"],
};'''
new_queries = '''const dateEnergyQueries = {
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
  if (occasion === "First date") return ["conversation friendly restaurant", "cozy cafe"];
  if (occasion === "Anniversary") return ["romantic fine dining restaurant", "special occasion restaurant"];
  if (occasion === "Surprise") return ["unique restaurant", "rooftop restaurant"];
  return ["romantic restaurant", "intimate local restaurant"];
}

function dateNightScore(place, occasion, style) {
  const text = [place.name, place.matchedQuery, ...(place.types || [])].join(" ").toLowerCase();
  const occasionSignals = {
    "First date": ["conversation", "gallery", "museum", "mini golf", "coffee", "book"],
    Anniversary: ["romantic", "scenic", "garden", "wine", "fine dining", "special occasion"],
    Surprise: ["unique", "adventure", "comedy", "dance", "tour", "live music"],
    "Regular date": ["couples", "music", "cooking", "mini golf", "comedy"],
  };
  const styleSignals = {
    Cozy: ["cozy", "jazz", "book", "wine", "intimate"],
    Playful: ["mini golf", "comedy", "arcade", "dance"],
    Romantic: ["romantic", "garden", "scenic", "gallery", "music"],
    Adventurous: ["kayak", "climbing", "hiking", "adventure"],
  };
  let score = rank(place);
  for (const signal of occasionSignals[occasion] || []) if (text.includes(signal)) score += 4;
  for (const signal of styleSignals[style] || []) if (text.includes(signal)) score += 3;
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
    const start = day === 0 || day === 6 ? now : new Date(Date.UTC(
      now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() + daysUntilSaturday,
    ));
    const end = new Date(start);
    end.setUTCDate(end.getUTCDate() + (start.getUTCDay() === 0 ? 1 : 2));
    end.setUTCHours(0, 0, 0, 0);
    return {start, end};
  }
  return {start: now, end: new Date(now.getTime() + 14 * 86400000)};
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
  for (const signal of [...(signals[occasion] || []), ...(signals[style] || [])]) {
    if (text.includes(signal)) score += 2;
  }
  return score;
}

async function findDateNightEvent({apiKey, lat, lng, radiusMiles, timing, occasion, style}) {
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
      .map((event) => ({event, score: dateEventScore(event, occasion, style)}))
      .filter((candidate) => candidate.score >= 2)
      .sort((a, b) => b.score - a.score)[0]?.event || null;
  } catch (error) {
    console.warn("Date Night event search skipped:", error.message);
    return null;
  }
}'''
backend = must_replace(backend, old_queries, new_queries, "Date Night backend helpers")

old_description = '''function placeDescription(place, isFood, isDateNight, index) {
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
}'''
new_description = '''function placeDescription(
  place,
  isFood,
  isDateNight,
  index,
  dateOccasion = "Regular date",
  dateStyle = "Romantic",
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
}'''
backend = must_replace(backend, old_description, new_description, "Date Night descriptions")

backend = must_replace(
    backend,
    'export const getIdeas = onRequest(\n  {\n    region: "us-central1",\n    secrets: [GOOGLE_API_KEY, REVENUECAT_SECRET_API_KEY],',
    'export const getIdeas = onRequest(\n  {\n    region: "us-central1",\n    secrets: [GOOGLE_API_KEY, REVENUECAT_SECRET_API_KEY, TICKETMASTER_API_KEY],',
    "Date Night Ticketmaster secret",
)

start = backend.index('      const budget = req.body?.budget || "$30–$75";', backend.index('export const getIdeas = onRequest('))
end_marker = '      return res.json(selected.map((place, index) => {'
return_start = backend.index(end_marker, start)
return_end = backend.index('      }));', return_start) + len('      }));')
old_core = backend[start:return_end]
new_core = '''      const budget = req.body?.budget || "$30–$75";
      const energy = req.body?.energy || "Medium";
      const group = req.body?.group || "Couple";
      const dateOccasion = String(req.body?.dateOccasion || "Regular date");
      const dateStyle = String(req.body?.dateStyle || "Romantic");
      const dateTiming = String(req.body?.dateTiming || "Tonight");
      const radiusMiles = Number(req.body?.radius) || 25;
      const radius = milesToMeters(radiusMiles);
      const googleKey = GOOGLE_API_KEY.value();

      const foodTerms = isDateNight ?
        dateNightFoodTerms(dateOccasion, budget) :
        (foodQueries[budget] || foodQueries["$"]);
      const experienceTerms = isDateNight ?
        dateNightTerms(dateOccasion, dateStyle, energy) :
        (activityQueries[energy] || activityQueries.Medium)
          .map((term) => group === "Family" ? `family friendly ${term}` : term);

      const [foodResults, experienceResults, recentIds, dateEvent] = await Promise.all([
        searchPlaces(googleKey, foodTerms, lat, lng, radius),
        searchPlaces(googleKey, experienceTerms, lat, lng, radius),
        recentRecommendationIds(user.uid),
        isDateNight ? findDateNightEvent({
          apiKey: TICKETMASTER_API_KEY.value(),
          lat,
          lng,
          radiusMiles,
          timing: dateTiming,
          occasion: dateOccasion,
          style: dateStyle,
        }) : Promise.resolve(null),
      ]);

      const unseenFood = foodResults
        .filter((place) => !recentIds.has(place.place_id))
        .filter((place) => priceAllowed(place, budget));
      const unseenExperiences = experienceResults
        .filter((place) => !recentIds.has(place.place_id));
      const food = unseenFood.length ? unseenFood : foodResults;
      let experiences = unseenExperiences.length ? unseenExperiences : experienceResults;
      if (isDateNight) {
        experiences = [...experiences].sort(
          (a, b) => dateNightScore(b, dateOccasion, dateStyle) -
            dateNightScore(a, dateOccasion, dateStyle),
        );
      }

      const selectedExperiences = [];
      for (const place of experiences) {
        if (selectedExperiences.length === 3) break;
        const duplicateCategory = selectedExperiences.some(
          (selected) => activityCategory(selected) === activityCategory(place),
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
      const eligibleDateEvent = dateEvent && !recentIds.has(dateEvent.id) ? dateEvent : null;
      const selected = isDateNight && eligibleDateEvent ?
        (foodChoice ?
          [eligibleDateEvent, foodChoice, ...selectedExperiences.slice(0, 2)] :
          [eligibleDateEvent, ...selectedExperiences.slice(0, 3)]) :
        (foodChoice ?
          [foodChoice, ...selectedExperiences.slice(0, 3)] :
          experiences.slice(0, 4));

      if (selected.length < 4) {
        return res.status(404).json({
          error: "We could not find four strong, different options nearby.",
        });
      }

      if (!premium) await consumeFreeRequest(user.uid);
      await rememberRecommendations(
        user.uid,
        selected.map((place) => place.place_id || place.id),
      );

      return res.json(selected.map((place, index) => {
        if (place.category === "event") return place;
        const isFood = place === foodChoice;
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
      }));'''
backend = backend[:start] + new_core + backend[return_end:]
backend_path.write_text(backend, encoding="utf-8")
