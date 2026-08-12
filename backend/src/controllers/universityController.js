const prisma = require("../config/db");

async function list(req, res, next) {
  try {
    const { region, countryId, search } = req.query;
    const where = {};
    if (countryId) where.countryId = countryId;
    if (region) where.country = { region };
    if (search) where.name = { contains: search, mode: "insensitive" };

    const universities = await prisma.university.findMany({
      where,
      include: { country: true, _count: { select: { programmes: true } } },
      orderBy: { name: "asc" },
    });
    return res.json(universities);
  } catch (err) {
    next(err);
  }
}

async function detail(req, res, next) {
  try {
    const university = await prisma.university.findUnique({
      where: { id: req.params.id },
      include: { country: true, programmes: true },
    });
    if (!university) return res.status(404).json({ error: "Not found" });
    return res.json(university);
  } catch (err) {
    next(err);
  }
}

// ---- Admin-only mutations ----

async function create(req, res, next) {
  try {
    const university = await prisma.university.create({ data: req.body });
    return res.status(201).json(university);
  } catch (err) {
    next(err);
  }
}

async function update(req, res, next) {
  try {
    const university = await prisma.university.update({
      where: { id: req.params.id },
      data: req.body,
    });
    return res.json(university);
  } catch (err) {
    next(err);
  }
}

async function remove(req, res, next) {
  try {
    await prisma.university.delete({ where: { id: req.params.id } });
    return res.status(204).send();
  } catch (err) {
    next(err);
  }
}

module.exports = { list, detail, create, update, remove };
