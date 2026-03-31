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

    /// 🔥 EVENTS ONLY IF NOT DATE NIGHT
    if (!isDateNight && ticketKey) {
      try {
        const eventRes = await fetch(
          `https://app.ticketmaster.com/discovery/v2/events.json?apikey=${ticketKey}&keyword=${location}&size=5`
        );

        const eventData = await eventRes.json();

        if (eventData._embedded?.events?.length > 0) {
          return res.json(
            eventData._embedded.events.slice(0, 2).map((e) => ({
              title: `🎟 ${e.name}`,
              description: `${e.dates.start.localDate} at ${e._embedded.venues[0].name}`,
              group,
              budget,
            }))
          );
        }
      } catch (e) {
        console.log("Event fetch failed, using AI");
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

Rules:
- MUST include 2–3 different places
- MUST feel like a real evening plan
- MUST be romantic or fun
- NO generic ideas
- NEVER repeat: ${history.join(", ")}
- ALL places MUST be in or near: ${location}
- DO NOT mix cities or states
`;

    /// 🔥 NORMAL MODE PROMPT
    const normalPrompt = `
Generate 3 fun activity ideas.

Location: ${location}

STRICT:
- ALL places MUST be within the SAME city or nearby area
- DO NOT mix cities or states

Return JSON:
[
  {
    "title": "Short name",
    "description": "Include place name + address",
    "group": "${group}",
    "budget": "${budget}"
  }
]
`;

    const prompt = isDateNight ? dateNightPrompt : normalPrompt;

    const completion = await openai.chat.completions.create({
      model: "gpt-4o-mini",
      messages: [{ role: "user", content: prompt }],
      temperature: 1.2,
    });

    let data = safeParse(completion.choices[0].message.content);

    /// 🔥 FORMAT DATE NIGHT INTO UI
    if (isDateNight) {
      data = data.map((item) => ({
        title: item.title,
        description:
          `✨ ${item.vibe}\n\nStart: ${item.start}\nThen: ${item.then}\nOptional: ${item.optional}`,
        group: "Couple",
        budget: "$$",
      }));
    }

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