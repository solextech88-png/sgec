/**
 * All AI features (university recommendation, essay/CV review, admission
 * chance prediction, 24/7 Q&A) route through this one module. That means
 * you can swap providers/models, add caching, or add guardrails/logging in
 * exactly one place instead of hunting through every controller.
 *
 * Uses the Anthropic Messages API. Set ANTHROPIC_API_KEY in .env.
 */

const MODEL = process.env.AI_MODEL || "claude-sonnet-4-6";

async function callClaude(systemPrompt, userMessage, maxTokens = 1024) {
  const res = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-api-key": process.env.ANTHROPIC_API_KEY,
      "anthropic-version": "2023-06-01",
    },
    body: JSON.stringify({
      model: MODEL,
      max_tokens: maxTokens,
      system: systemPrompt,
      messages: [{ role: "user", content: userMessage }],
    }),
  });

  if (!res.ok) {
    const text = await res.text();
    throw new Error(`AI provider error (${res.status}): ${text}`);
  }

  const data = await res.json();
  return data.content
    .filter((block) => block.type === "text")
    .map((block) => block.text)
    .join("\n");
}

async function recommendProgrammes(studentProfile, availableProgrammesSummary) {
  const system =
    "You are an education-consultancy assistant. Given a student's " +
    "qualifications and a list of candidate programmes, recommend the best " +
    "fits and briefly justify each. Be concrete about gaps in eligibility. " +
    "Respond ONLY as JSON: an array of {programmeId, matchScore (0-100), reason}.";
  const user = JSON.stringify({ studentProfile, availableProgrammesSummary });
  return callClaude(system, user, 1500);
}

async function predictAdmissionChance(studentProfile, programme) {
  const system =
    "You estimate a student's likely admission chance (0-100) for a given " +
    "programme based on entry requirements vs their qualifications. " +
    "Respond ONLY as JSON: {score, reasoning}.";
  const user = JSON.stringify({ studentProfile, programme });
  return callClaude(system, user, 500);
}

async function reviewDocument(kind, text) {
  // kind: "personal_statement" | "cv" | "research_proposal"
  const system =
    `You are reviewing a student's ${kind.replace("_", " ")} for a ` +
    "university application. Give specific, actionable feedback: structure, " +
    "clarity, and anything that would weaken the application. Do not rewrite " +
    "the whole document — point to specific passages and suggest fixes.";
  return callClaude(system, text, 1200);
}

async function chat(studentContext, message) {
  const system =
    "You are the 24/7 AI assistant inside an education-consultancy app. " +
    "Answer questions about universities, programmes, visas, and the " +
    "application process. If a question requires a human decision " +
    "(e.g. final application review), say so and suggest contacting their " +
    "assigned consultant.";
  const user = `Student context: ${JSON.stringify(studentContext)}\n\nQuestion: ${message}`;
  return callClaude(system, user, 800);
}

module.exports = { recommendProgrammes, predictAdmissionChance, reviewDocument, chat };
