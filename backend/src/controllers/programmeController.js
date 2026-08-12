const prisma = require("../config/db");

async function list(req, res, next) {
  try {
    const { universityId, level, isNextIntake, fieldOfStudy, search } = req.query;
    const where = {};
    if (universityId) where.universityId = universityId;
    if (level) where.level = level;
    if (isNextIntake !== undefined) where.isNextIntake = isNextIntake === "true";
    if (fieldOfStudy) where.fieldOfStudy = { contains: fieldOfStudy, mode: "insensitive" };
    if (search) where.name = { contains: search, mode: "insensitive" };

    const programmes = await prisma.programme.findMany({
      where,
      include: { university: { include: { country: true } } },
      orderBy: { applicationDeadline: "asc" },
    });
    return res.json(programmes);
  } catch (err) {
    next(err);
  }
}

async function detail(req, res, next) {
  try {
    const programme = await prisma.programme.findUnique({
      where: { id: req.params.id },
      include: { university: { include: { country: true } } },
    });
    if (!programme) return res.status(404).json({ error: "Not found" });
    return res.json(programme);
  } catch (err) {
    next(err);
  }
}

/**
 * AI-assisted matching: given a studentId, score every programme (or a
 * filtered subset) against their profile. This delegates the actual
 * scoring to utils/aiClient.js — see recommendController.js for the
 * dedicated /ai/recommend endpoint, which is the one the mobile app should
 * call from the student-facing "Recommended for you" screen.
 */

async function create(req, res, next) {
  try {
    const programme = await prisma.programme.create({ data: req.body });
    return res.status(201).json(programme);
  } catch (err) {
    next(err);
  }
}

async function update(req, res, next) {
  try {
    const programme = await prisma.programme.update({
      where: { id: req.params.id },
      data: req.body,
    });
    return res.json(programme);
  } catch (err) {
    next(err);
  }
}

async function remove(req, res, next) {
  try {
    await prisma.programme.delete({ where: { id: req.params.id } });
    return res.status(204).send();
  } catch (err) {
    next(err);
  }
}

module.exports = { list, detail, create, update, remove };
