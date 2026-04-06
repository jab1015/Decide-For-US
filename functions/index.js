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
      location = "Jacksonville, FL",
    } = req.body;

    /// 🎟️ FETCH LOCAL EVENTS
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
            .map((e) => {
              const venue = e._embedded.venues[0];
              return `${e.name} at ${venue.name}, ${venue.address?.line1 || ""}, ${venue.city.name}, ${venue.state?.stateCode || ""}`;
            })
            .join("\n");
        }
      } catch (e) {
        console.log("Ticketmaster error:", e.message);
      }
    }

    if (!openaiKey) {
      return res.json([
        {
          title: "Error",
          description: "Missing OpenAI key",
          address: "",
          group: "Error",
          budget: "Error",
        },
      ]);
    }

    const openai = new OpenAI({ apiKey: openaiKey });

    /// 💎 PREMIUM DATE NIGHT PROMPT
    const dateNightPrompt = `
You are a HIGH-END ROMANTIC EXPERIENCE PLANNER.

Location: ${location}

Here are real local events:
${eventSummary}

GOAL:
Create a UNIQUE, MEMORABLE DATE NIGHT that feels intentional, romantic, and special.

STRICT RULES:
- MUST include 2–3 REAL locations
- MUST feel romantic, cozy, fun, or exciting
- MUST include FULL ADDRESS (street, city, state)
- MUST NOT be generic (no "dinner and a movie")
- MUST feel like something worth dressing up for
- MUST avoid repeats: ${history.join(", ")}

EXPERIENCE STYLE:
- Think: atmosphere, mood, flow
- Include variety (drinks → activity → dessert)
- Use aesthetic or unique places (rooftops, waterfronts, live music, hidden gems)

FLOW:
- Start: engaging opener (views, drinks, fun start)
- Middle: main experience (dinner/event/activity)
- Optional Finish: dessert, scenic walk, relaxed ending

TONE:
- Romantic, exciting, elevated

Return ONLY JSON:

[
  {
    "title": "Romantic experience name",
    "description": "Start at [place + full address] for [vibe], then head to [place + full address], and optionally finish at [place + full address]",
    "address": "First location full address",
    "group": "Couple",
    "budget": "$$"
  }
]
`;

    /// 🔥 PREMIUM NORMAL PROMPT
    const normalPrompt = `
You are a HIGH-END LOCAL EXPERIENCE CURATOR.

Location: ${location}

Here are real local events:
${eventSummary}

GOAL:
Create PREMIUM, curated experiences — not simple ideas.

STRICT RULES:
- MUST include real businesses or events
- MUST include FULL address
- MUST chain 2–3 steps together
- MUST feel intentional and exciting
- NEVER generic ideas
- NEVER repeat: ${history.join(", ")}

FILTERS:
Group: ${group}
Budget: ${budget}
Energy: ${energy}

STYLE:
- Think like a concierge
- Make it feel planned and special

Return ONLY JSON:

[
  {
    "title": "Experience name",
    "description": "Start at [place + full address], then go to [place + full address], optional final stop [place + full address]",
    "address": "First location full address",
    "group": "${group}",
    "budget": "${budget}"
  }
]
`;

    const prompt = isDateNight ? dateNightPrompt : normalPrompt;

    /// 🤖 CALL OPENAI
    const completion = await openai.chat.completions.create({
      model: "gpt-4o-mini",
      messages: [{ role: "user", content: prompt }],
      temperature: 1.2,
    });

    let data = safeParse(completion.choices[0].message.content);

    /// 🧹 CLEAN RESPONSE
    data = data.map((item) => ({
      title: item.title || "",
      description: item.description || "",
      address: item.address || "",
      group: item.group || group,
      budget: item.budget || budget,
    }));

    return res.json(data);

  } catch (err) {
    console.error("ERROR:", err);

    return res.json([
      {
        title: "Error",
        description: err.message,
        address: "",
        group: "Error",
        budget: "Error",
      },
    ]);
  }
});

exports.getIdeas = functions.https.onRequest(app);