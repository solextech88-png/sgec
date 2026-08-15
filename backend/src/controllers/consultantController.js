const bcrypt = require("bcryptjs");
const prisma = require("../config/db");

async function list(req, res, next) {
  try {
    const consultants = await prisma.consultantProfile.findMany({
      include: {
        user: { select: { email: true, phone: true } },
        students: { select: { id: true, firstName: true, lastName: true } },
      },
      orderBy: { firstName: "asc" },
    });
    return res.json(consultants);
  } catch (err) {
    next(err);
  }
}

/**
 * Admin-only: creates a consultant account directly (email + temp password
 * + name), skipping the normal self-registration flow — registration only
 * ever creates STUDENT accounts (see authController.register), and there's
 * intentionally no public "sign up as a consultant" endpoint. The
 * consultant logs in with the email/password given here.
 */
async function create(req, res, next) {
  try {
    const { email, password, firstName, lastName, specialties } = req.body;
    if (!email || !password || !firstName || !lastName) {
      return res.status(400).json({ error: "email, password, firstName, lastName are required" });
    }

    const existing = await prisma.user.findFirst({ where: { email } });
    if (existing) {
      return res.status(409).json({ error: "A user with this email already exists" });
    }

    const passwordHash = await bcrypt.hash(password, 12);
    const user = await prisma.user.create({
      data: {
        email,
        passwordHash,
        role: "CONSULTANT",
        isEmailVerified: true, // admin-created, skip OTP step
        consultant: {
          create: {
            firstName,
            lastName,
            specialties: Array.isArray(specialties) ? specialties : [],
          },
        },
      },
      include: { consultant: true },
    });

    return res.status(201).json(user.consultant);
  } catch (err) {
    next(err);
  }
}

module.exports = { list, create };
