const functions = require("firebase-functions");
const express = require("express");
const cors = require("cors");
const OpenAI = require("openai");
const fetch = require("node-fetch");

const app = express();
app.use(cors({ origin: true }));
app.use(express.json());

function safeParse(text) {
  try {
    return JSON.parse(text);
  } catch (e) {
    const match = text.match(/\[[\s\S]*\]/);
    if (match) return JSON.parse(match[0]);
    throw new Error("Invalid JSON from AI");
  }
}

app.post("/", async (req, res) => {
  try {
    const openaiKey = process.env.OPENAI_API_KEY;
    const ticketKey = process.env.TICKETMASTER_API_KEY;

    const {
      group = "Any",
      budget = "Any",
      energy = "Any",
      isDateNight = false,
      history = [],
      location = "United States",
    } = req.body;

    /// 🔥 STEP 1: FETCH EVENTS (ALWAYS, NOT CONDITIONAL)
    let eventSummary = "";

    if (ticketKey) {
      try {
        const eventRes = await fetch(
          `https://app.ticketmaster.com/discovery/v2/events.json?apikey=${ticketKey}&keyword=${location}&size=5`
        );

        const eventData = await eventRes.json();

        if (eventData._embedded?.events?.length > 0) {
          eventSummary = eventData._embedded.events
            .slice(0, 5)
            .map(
              (e) =>
                `${e.name} at ${e._embedded.venues[0].name} (${e.dates.start.localDate})`
            )
            .join("\n");
        }
      } catch (e) {
        console.log("⚠️ Ticketmaster failed:", e.message);
      }
    }

    /// ❌ NO OPENAI KEY
    if (!openaiKey) {
      return res.json([
        {
          title: "❌ ERROR",
          description: "Missing OpenAI API Key",
          group: "Error",
          budget: "Error",
        },
      ]);
    }

    const openai = new OpenAI({ apiKey: openaiKey });

    /// 💎 DATE NIGHT PROMPT
    const dateNightPrompt = `
You are a DATE NIGHT PLANNER.

Use real local places and events when possible:

${eventSummary}

STRICT RULES:
- MUST include 2–3 different places
- MUST feel like a real evening plan
- MUST be romantic or fun
- NEVER generic ideas
- NEVER repeat: ${history.join(", ")}
- ALL places MUST be near: ${location}

Return ONLY JSON:

[
  {
    "title": "Short catchy name",
    "start": "Place + address",
    "then": "Place + address",
    "optional": "Place + address",
    "vibe": "short emotional hook"
  }
]
`;

    /// 🔥 NORMAL MODE PROMPT (FIXED)
    const normalPrompt = `
You are a creative local planner.

Use REAL events when helpful:

${eventSummary}

Filters:
Group: ${group}
Budget: ${budget}
Energy: ${energy}

STRICT RULES:
- NEVER suggest "dinner and a movie"
- Avoid generic ideas completely
- Use real places or realistic local ideas
- Respect ALL filters
- Make ideas feel like something someone would actually do

Return JSON:
[
  {
    "title": "Short name",
    "description": "Include real place + what to do",
    "group": "${group}",
    "budget": "${budget}"
  }
]
`;

    const prompt = isDateNight ? dateNightPrompt : normalPrompt;

    /// 🔥 CALL OPENAI
    const completion = await openai.chat.completions.create({
      model: "gpt-4o-mini",
      messages: [{ role: "user", content: prompt }],
      temperature: 1.2,
    });

    let data = safeParse(completion.choices[0].message.content);

    /// 💎 FORMAT DATE NIGHT FOR UI
    if (isDateNight) {
      data = data.map((item) => ({
        title: item.title,
        description:
          `✨ ${item.vibe}\n\nStart: ${item.start}\nThen: ${item.then}\nOptional: ${item.optional}`,
        group: "Couple",
        budget: "$$",
      }));
    }

    /// 🔥 FINAL RESPONSE
    return res.json(data);

  } catch (err) {
    console.error("❌ ERROR:", err);

    return res.json([
      {
        title: "❌ ERROR",
        description: err.message,
        group: "Error",
        budget: "Error",
      },
    ]);
  }
});

exports.getIdeas = functions.https.onRequest(app);