const prisma = require("../config/db");

// A student can only ever read/write their OWN profile through these
// endpoints — consultants/admins use the separate consultant routes to
// look up a specific student by id.

async function getMyProfile(req, res, next) {
  try {
    const profile = await prisma.studentProfile.findUnique({
      where: { userId: req.user.id },
      include: { documents: true, assignedConsultant: true },
    });
    if (!profile) return res.status(404).json({ error: "Profile not found" });
    return res.json(profile);
  } catch (err) {
    next(err);
  }
}

async function updateMyProfile(req, res, next) {
  try {
    const allowedFields = [
      "firstName", "lastName", "dateOfBirth", "nationality",
      "countryOfResidence", "gender", "passportNumber",
      "highestQualification", "gpaOrGrade", "englishTestType", "englishTestScore",
    ];
    const data = {};
    for (const field of allowedFields) {
      if (req.body[field] !== undefined) data[field] = req.body[field];
    }

    const profile = await prisma.studentProfile.update({
      where: { userId: req.user.id },
      data,
    });
    return res.json(profile);
  } catch (err) {
    next(err);
  }
}

// ---- Consultant/Admin: manage any student ----

async function listAll(req, res, next) {
  try {
    const students = await prisma.studentProfile.findMany({
      include: { user: { select: { email: true, phone: true } } },
      orderBy: { createdAt: "desc" },
    });
    return res.json(students);
  } catch (err) {
    next(err);
  }
}

async function getById(req, res, next) {
  try {
    const student = await prisma.studentProfile.findUnique({
      where: { id: req.params.id },
      include: {
        documents: true,
        applications: { include: { programme: true } },
        consentSignatures: { include: { consentForm: true } },
      },
    });
    if (!student) return res.status(404).json({ error: "Not found" });
    return res.json(student);
  } catch (err) {
    next(err);
  }
}

async function assignConsultant(req, res, next) {
  try {
    const { consultantId } = req.body;
    const student = await prisma.studentProfile.update({
      where: { id: req.params.id },
      data: { assignedConsultantId: consultantId },
    });
    return res.json(student);
  } catch (err) {
    next(err);
  }
}

module.exports = { getMyProfile, updateMyProfile, listAll, getById, assignConsultant };
