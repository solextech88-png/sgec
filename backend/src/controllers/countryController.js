const prisma = require("../config/db");

async function list(req, res, next) {
  try {
    const { region } = req.query; // "UK" | "Ireland" | "Europe"
    const where = region ? { region } : {};
    const countries = await prisma.country.findMany({
      where,
      orderBy: { name: "asc" },
      include: { _count: { select: { universities: true } } },
    });
    return res.json(countries);
  } catch (err) {
    next(err);
  }
}

async function create(req, res, next) {
  try {
    const country = await prisma.country.create({ data: req.body });
    return res.status(201).json(country);
  } catch (err) {
    next(err);
  }
}

async function update(req, res, next) {
  try {
    const country = await prisma.country.update({
      where: { id: req.params.id },
      data: req.body,
    });
    return res.json(country);
  } catch (err) {
    next(err);
  }
}

async function remove(req, res, next) {
  try {
    await prisma.country.delete({ where: { id: req.params.id } });
    return res.status(204).send();
  } catch (err) {
    next(err);
  }
}

module.exports = { list, create, update, remove };
