const bcrypt = require("bcryptjs");
const { z } = require("zod");
const prisma = require("../config/db");
const { signAccessToken } = require("../utils/tokens");
const { issueOtp, verifyOtp } = require("../utils/otp");

const registerSchema = z.object({
  email: z.string().email().optional(),
  phone: z.string().min(6).optional(),
  password: z.string().min(8),
  firstName: z.string().min(1),
  lastName: z.string().min(1),
}).refine((data) => data.email || data.phone, {
  message: "Either email or phone is required",
});

async function register(req, res, next) {
  try {
    const data = registerSchema.parse(req.body);

    const existing = await prisma.user.findFirst({
      where: { OR: [{ email: data.email }, { phone: data.phone }] },
    });
    if (existing) {
      return res.status(409).json({ error: "An account with this email/phone already exists" });
    }

    const passwordHash = await bcrypt.hash(data.password, 12);

    const user = await prisma.user.create({
      data: {
        email: data.email,
        phone: data.phone,
        passwordHash,
        role: "STUDENT",
        student: {
          create: { firstName: data.firstName, lastName: data.lastName },
        },
      },
      include: { student: true },
    });

    // Kick off OTP verification on whichever channel they registered with.
    if (data.email) await issueOtp(user.id, "email");
    if (data.phone) await issueOtp(user.id, "phone");

    return res.status(201).json({
      message: "Registered. Check your email/phone for a verification code.",
      userId: user.id,
    });
  } catch (err) {
    next(err);
  }
}

async function sendOtp(req, res, next) {
  try {
    const { userId, channel } = req.body; // channel: "email" | "phone"
    await issueOtp(userId, channel);
    return res.json({ message: "OTP sent" });
  } catch (err) {
    next(err);
  }
}

async function confirmOtp(req, res, next) {
  try {
    const { userId, code, channel } = req.body;
    const ok = await verifyOtp(userId, code);
    if (!ok) return res.status(400).json({ error: "Invalid or expired code" });

    const field = channel === "phone" ? { isPhoneVerified: true } : { isEmailVerified: true };
    const user = await prisma.user.update({ where: { id: userId }, data: field });

    const token = signAccessToken(user);
    return res.json({ token, role: user.role });
  } catch (err) {
    next(err);
  }
}

const loginSchema = z.object({
  identifier: z.string(), // email or phone
  password: z.string(),
});

async function login(req, res, next) {
  try {
    const { identifier, password } = loginSchema.parse(req.body);

    const user = await prisma.user.findFirst({
      where: { OR: [{ email: identifier }, { phone: identifier }] },
    });
    if (!user || !user.passwordHash) {
      return res.status(401).json({ error: "Invalid credentials" });
    }

    const valid = await bcrypt.compare(password, user.passwordHash);
    if (!valid) return res.status(401).json({ error: "Invalid credentials" });

    const token = signAccessToken(user);
    return res.json({ token, role: user.role });
  } catch (err) {
    next(err);
  }
}

/**
 * TODO: Google/Apple sign-in.
 * Flow: mobile app performs the native Google/Apple sign-in, sends the
 * resulting ID token here. This endpoint verifies it against Google's/
 * Apple's public keys (e.g. `google-auth-library`), then finds-or-creates
 * the User with authProvider set accordingly, and returns our own JWT.
 * Stubbed so the route exists and the mobile app can be built against it.
 */
async function socialAuth(req, res, next) {
  try {
    const { provider, idToken } = req.body; // provider: "GOOGLE" | "APPLE"
    return res.status(501).json({
      error: `Social auth for ${provider} not implemented yet — verify idToken server-side before issuing a session.`,
    });
  } catch (err) {
    next(err);
  }
}

module.exports = { register, login, sendOtp, confirmOtp, socialAuth };
