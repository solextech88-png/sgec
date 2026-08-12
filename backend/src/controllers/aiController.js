const prisma = require("../config/db");
const aiClient = require("../utils/aiClient");

async function recommend(req, res, next) {
  try {
    const student = await prisma.studentProfile.findUnique({ where: { userId: req.user.id } });
    const candidateProgrammes = await prisma.programme.findMany({
      where: { isNextIntake: true },
      take: 50,
      include: { university: { include: { country: true } } },
    });

    const summary = candidateProgrammes.map((p) => ({
      programmeId: p.id,
      name: p.name,
      level: p.level,
      university: p.university.name,
      country: p.university.country.name,
      entryRequirements: p.entryRequirements,
      englishRequirement: p.englishRequirement,
    }));

    const result = await aiClient.recommendProgrammes(student, summary);
    return res.json({ raw: result });
  } catch (err) {
    next(err);
  }
}

async function admissionChance(req, res, next) {
  try {
    const student = await prisma.studentProfile.findUnique({ where: { userId: req.user.id } });
    const programme = await prisma.programme.findUnique({ where: { id: req.params.programmeId } });
    if (!programme) return res.status(404).json({ error: "Programme not found" });

    const result = await aiClient.predictAdmissionChance(student, programme);
    return res.json({ raw: result });
  } catch (err) {
    next(err);
  }
}

async function reviewDocument(req, res, next) {
  try {
    const { kind, text } = req.body; // kind: personal_statement | cv | research_proposal
    const result = await aiClient.reviewDocument(kind, text);
    return res.json({ feedback: result });
  } catch (err) {
    next(err);
  }
}

async function chat(req, res, next) {
  try {
    const { message } = req.body;
    const student = await prisma.studentProfile.findUnique({ where: { userId: req.user.id } });
    const result = await aiClient.chat(student, message);
    return res.json({ reply: result });
  } catch (err) {
    next(err);
  }
}

module.exports = { recommend, admissionChance, reviewDocument, chat };
