require("dotenv").config();
const express = require("express");
const cors = require("cors");
const helmet = require("helmet");
const path = require("path");

const errorHandler = require("./middleware/errorHandler");

const authRoutes = require("./routes/auth");
const studentRoutes = require("./routes/students");
const documentRoutes = require("./routes/documents");
const consentRoutes = require("./routes/consent");
const countryRoutes = require("./routes/countries");
const universityRoutes = require("./routes/universities");
const programmeRoutes = require("./routes/programmes");
const applicationRoutes = require("./routes/applications");
const chatRoutes = require("./routes/chat");
const notificationRoutes = require("./routes/notifications");
const aiRoutes = require("./routes/ai");

const app = express();

app.use(helmet());
app.use(cors()); // TODO: restrict origins before production
app.use(express.json({ limit: "2mb" }));

// Serves locally-stored uploads in dev only. In production, swap the
// storage driver to S3 and remove this — documents should be served via
// short-lived signed URLs, never a public static route.
if (process.env.STORAGE_DRIVER !== "s3") {
  app.use("/uploads", express.static(path.join(__dirname, "..", process.env.LOCAL_STORAGE_DIR || "uploads")));
}

app.get("/health", (req, res) => res.json({ status: "ok" }));

/**
 * One-time seed trigger, for hosts (like Render's free tier) that don't
 * provide shell/SSH access to run `node prisma/seed.js` directly.
 * Protected by a token so randoms can't trigger it, and it's a no-op if
 * data already exists so it's safe to hit more than once by accident.
 * Visit: https://<your-app>.onrender.com/admin/seed?token=<SEED_TOKEN>
 * Remove this route once you have real admin tooling / shell access.
 */
/**
 * One-time promotion tool: registration always creates a STUDENT account,
 * and there's no public "become admin" flow (by design — that would be a
 * serious security hole). To get an admin account on a host with no shell
 * access, register a normal account in the app first, then hit this once
 * with that account's email to flip it to ADMIN. Protected by the same
 * token as /admin/seed. After promoting, log out and back in on the
 * phone — the JWT carries the role, so an old token won't reflect the
 * change until a fresh login mints a new one.
 * Visit: https://<your-app>.onrender.com/admin/promote?token=<SEED_TOKEN>&email=<the account's email>
 */
app.get("/admin/promote", async (req, res) => {
  try {
    if (!process.env.SEED_TOKEN || req.query.token !== process.env.SEED_TOKEN) {
      return res.status(403).json({ error: "Invalid or missing token" });
    }
    const { email, firstName, lastName } = req.query;
    if (!email) {
      return res.status(400).json({ error: "Provide ?email=the-account-email" });
    }

    const prisma = require("./config/db");
    const user = await prisma.user.findUnique({ where: { email } });
    if (!user) {
      return res.status(404).json({ error: `No user found with email ${email}` });
    }

    await prisma.user.update({ where: { id: user.id }, data: { role: "ADMIN" } });

    const existingAdminProfile = await prisma.adminProfile.findUnique({ where: { userId: user.id } });
    if (!existingAdminProfile) {
      await prisma.adminProfile.create({
        data: {
          userId: user.id,
          firstName: firstName || "Admin",
          lastName: lastName || "User",
        },
      });
    }

    return res.json({ message: `${email} is now an ADMIN. Log out and back in on the phone to see it take effect.` });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

app.get("/admin/seed", async (req, res) => {
  try {
    if (!process.env.SEED_TOKEN || req.query.token !== process.env.SEED_TOKEN) {
      return res.status(403).json({ error: "Invalid or missing token" });
    }

    const prisma = require("./config/db");
    const existing = await prisma.country.count();
    if (existing > 0) {
      return res.json({ message: "Already seeded — skipping.", countryCount: existing });
    }

    const countries = await Promise.all(
      [
        { name: "United Kingdom", isoCode: "GB", region: "UK" },
        { name: "Ireland", isoCode: "IE", region: "Ireland" },
        { name: "Germany", isoCode: "DE", region: "Europe" },
        { name: "Netherlands", isoCode: "NL", region: "Europe" },
        { name: "France", isoCode: "FR", region: "Europe" },
        { name: "Poland", isoCode: "PL", region: "Europe" },
        { name: "Sweden", isoCode: "SE", region: "Europe" },
      ].map((c) => prisma.country.upsert({ where: { isoCode: c.isoCode }, update: {}, create: c }))
    );

    const uk = countries.find((c) => c.isoCode === "GB");
    const ie = countries.find((c) => c.isoCode === "IE");
    const de = countries.find((c) => c.isoCode === "DE");

    const manchester = await prisma.university.create({
      data: { name: "University of Manchester", countryId: uk.id, city: "Manchester", type: "Public", websiteUrl: "https://www.manchester.ac.uk" },
    });
    const dcu = await prisma.university.create({
      data: { name: "Dublin City University", countryId: ie.id, city: "Dublin", type: "Public", websiteUrl: "https://www.dcu.ie" },
    });
    const tum = await prisma.university.create({
      data: { name: "Technical University of Munich", countryId: de.id, city: "Munich", type: "Public", websiteUrl: "https://www.tum.de" },
    });

    await prisma.programme.createMany({
      data: [
        {
          universityId: manchester.id, name: "MSc Data Science", level: "MSC", fieldOfStudy: "Computer Science",
          durationMonths: 12, tuitionFeeAmount: 28500, tuitionFeeCurrency: "GBP",
          entryRequirements: "2:1 UK Honours degree or international equivalent in a numerate discipline",
          englishRequirement: "IELTS 6.5 overall, no component below 6.0",
          applicationDeadline: new Date("2027-06-30"), scholarshipsAvailable: "International Merit Scholarship up to £5,000",
          campus: "Main Campus", startDates: ["September 2026", "September 2027"], casAvailable: true,
          dependantsPolicy: "Postgraduate taught students generally cannot bring dependants under current UK visa rules",
          visaInfo: "Student Route (Tier 4 successor) visa required", postGradWorkRights: "Graduate Route — 2 years post-study work visa",
          intakeCycle: "2026/27", isNextIntake: true,
        },
        {
          universityId: dcu.id, name: "MSc Artificial Intelligence", level: "MSC", fieldOfStudy: "Computer Science",
          durationMonths: 12, tuitionFeeAmount: 20500, tuitionFeeCurrency: "EUR",
          entryRequirements: "Level 8 Honours degree (2.2 or above) in a computing-related discipline",
          englishRequirement: "IELTS 6.5 overall, no component below 6.0",
          applicationDeadline: new Date("2027-07-15"), scholarshipsAvailable: "DCU International Excellence Scholarship",
          campus: "Glasnevin Campus", startDates: ["September 2026"], casAvailable: false,
          dependantsPolicy: "Not generally applicable for non-EEA postgraduate students on a Stamp 2 permission",
          visaInfo: "Irish study visa/preclearance required for many nationalities", postGradWorkRights: "Third Level Graduate Scheme — up to 2 years stay-back",
          intakeCycle: "2026/27", isNextIntake: true,
        },
        {
          universityId: tum.id, name: "MSc Mechanical Engineering", level: "MSC", fieldOfStudy: "Engineering",
          durationMonths: 24, tuitionFeeAmount: 0, tuitionFeeCurrency: "EUR",
          entryRequirements: "Bachelor's degree in Mechanical Engineering or closely related field",
          englishRequirement: "IELTS 6.5 or equivalent (English-taught track)",
          applicationDeadline: new Date("2027-05-31"), scholarshipsAvailable: "DAAD scholarships for select nationalities",
          campus: "Garching Campus", startDates: ["October 2026"], casAvailable: false,
          dependantsPolicy: "Family reunification possible under German residence permit rules",
          visaInfo: "German national (D) visa for study purposes required for most non-EU nationals",
          postGradWorkRights: "18-month job-seeker residence permit after graduation", intakeCycle: "2026/27", isNextIntake: true,
        },
      ],
    });

    await prisma.consentForm.upsert({
      where: { id: "00000000-0000-0000-0000-000000000001" },
      update: {},
      create: {
        id: "00000000-0000-0000-0000-000000000001",
        version: "v1.0-2026-01",
        title: "Authorization to Act on Your Behalf",
        bodyMarkdown:
          "I authorize Smart Global Education Consult to prepare and submit " +
          "university applications on my behalf using the documents and " +
          "information I provide, and to communicate with universities " +
          "regarding my applications. [PLACEHOLDER — replace with lawyer-" +
          "reviewed text before production use.]",
        countryScope: null,
      },
    });

    return res.json({ message: "Seed complete." });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

app.use("/api/auth", authRoutes);
app.use("/api/students", studentRoutes);
app.use("/api/documents", documentRoutes);
app.use("/api/consent", consentRoutes);
app.use("/api/countries", countryRoutes);
app.use("/api/universities", universityRoutes);
app.use("/api/programmes", programmeRoutes);
app.use("/api/applications", applicationRoutes);
app.use("/api/chat", chatRoutes);
app.use("/api/notifications", notificationRoutes);
app.use("/api/ai", aiRoutes);

app.use(errorHandler);

const PORT = process.env.PORT || 4000;
app.listen(PORT, () => console.log(`SGEC API listening on port ${PORT}`));
