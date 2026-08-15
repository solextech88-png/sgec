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
const consultantRoutes = require("./routes/consultants");

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
app.get("/admin/seed-more", async (req, res) => {
  try {
    if (!process.env.SEED_TOKEN || req.query.token !== process.env.SEED_TOKEN) {
      return res.status(403).json({ error: "Invalid or missing token" });
    }

    const prisma = require("./config/db");
    const countries = await prisma.country.findMany();
    const byIso = Object.fromEntries(countries.map((c) => [c.isoCode, c]));

    // Real universities/programmes with researched (approximate, subject to
    // change — verify against official pages before relying on these)
    // fees and requirements as of mid-2026. Safe to call more than once:
    // each university is only created if one with the same name doesn't
    // already exist.
    const additions = [
      {
        university: { name: "University of Edinburgh", countryIso: "GB", city: "Edinburgh", type: "Public", websiteUrl: "https://www.ed.ac.uk" },
        programme: {
          name: "MSc Artificial Intelligence", level: "MSC", fieldOfStudy: "Computer Science",
          durationMonths: 12, tuitionFeeAmount: 45410, tuitionFeeCurrency: "GBP",
          entryRequirements: "UK 2:1 honours degree or international equivalent in informatics, computer science, cognitive science, mathematics, or a related quantitative subject",
          englishRequirement: "IELTS 6.5 overall, minimum 6.0 in each component (standard requirement)",
          applicationDeadline: new Date("2027-03-31"), scholarshipsAvailable: "School of Informatics scholarships; 10% discount for Edinburgh alumni",
          campus: "Main Campus, Edinburgh", startDates: ["September 2026"], casAvailable: true,
          dependantsPolicy: "Postgraduate taught students generally cannot bring dependants under current UK visa rules",
          visaInfo: "Student Route visa required", postGradWorkRights: "Graduate Route — 2 years post-study work visa",
          intakeCycle: "2026/27", isNextIntake: true,
        },
      },
      {
        university: { name: "University College Dublin", countryIso: "IE", city: "Dublin", type: "Public", websiteUrl: "https://www.ucd.ie" },
        programme: {
          name: "MSc Data and Computational Science", level: "MSC", fieldOfStudy: "Data Science",
          durationMonths: 12, tuitionFeeAmount: 22530, tuitionFeeCurrency: "EUR",
          entryRequirements: "Upper second-class honours degree (2:1) or higher in a highly quantitative subject such as Mathematics, Physics, Statistics, or Engineering",
          englishRequirement: "IELTS 6.5 overall, no component below 6.0",
          applicationDeadline: new Date("2027-04-30"), scholarshipsAvailable: "UCD Global Excellence Scholarship",
          campus: "Belfield Campus, Dublin", startDates: ["September 2026"], casAvailable: false,
          dependantsPolicy: "Not generally applicable for non-EEA postgraduate students on a Stamp 2 permission",
          visaInfo: "Irish study visa/preclearance required for many nationalities", postGradWorkRights: "Third Level Graduate Scheme — up to 24 months stay-back",
          intakeCycle: "2026/27", isNextIntake: true,
        },
      },
      {
        university: { name: "Delft University of Technology", countryIso: "NL", city: "Delft", type: "Technological University", websiteUrl: "https://www.tudelft.nl" },
        programme: {
          name: "MSc Computer Science", level: "MSC", fieldOfStudy: "Computer Science",
          durationMonths: 24, tuitionFeeAmount: 25633, tuitionFeeCurrency: "EUR",
          entryRequirements: "Bachelor's degree in Computer Science or a closely related field with a strong quantitative background",
          englishRequirement: "IELTS 7.0 or TOEFL iBT 100",
          applicationDeadline: new Date("2027-01-15"), scholarshipsAvailable: "Justus & Louise van Effen Scholarship; Holland Scholarship (€5,000, non-EEA)",
          campus: "TU Delft Campus", startDates: ["September 2026"], casAvailable: false,
          dependantsPolicy: "Family reunification possible under Dutch residence permit rules",
          visaInfo: "Dutch entry visa/residence permit (MVV) required for most non-EU/EEA students", postGradWorkRights: "Orientation Year residence permit — up to 12 months to find work",
          intakeCycle: "2026/27", isNextIntake: true,
        },
      },
      {
        university: { name: "KTH Royal Institute of Technology", countryIso: "SE", city: "Stockholm", type: "Public", websiteUrl: "https://www.kth.se" },
        programme: {
          name: "MSc Machine Learning", level: "MSC", fieldOfStudy: "Computer Science",
          durationMonths: 24, tuitionFeeAmount: 180000, tuitionFeeCurrency: "SEK",
          entryRequirements: "Bachelor's degree with a strong foundation in mathematics and computer science (algorithms, data structures, linear algebra)",
          englishRequirement: "IELTS 6.5 overall or TOEFL 90 (Swedish upper-secondary English 6 equivalent)",
          applicationDeadline: new Date("2027-01-15"), scholarshipsAvailable: "KTH Global Scholarship; Swedish Institute Scholarships (select countries)",
          campus: "KTH Campus, Stockholm", startDates: ["August 2026"], casAvailable: false,
          dependantsPolicy: "Family reunification permit available for spouse/children",
          visaInfo: "Swedish residence permit for studies required for non-EU/EEA students", postGradWorkRights: "12-month post-study residence permit to seek work",
          intakeCycle: "2026/27", isNextIntake: true,
        },
      },
      {
        university: { name: "University of Amsterdam", countryIso: "NL", city: "Amsterdam", type: "Public", websiteUrl: "https://www.uva.nl" },
        programme: {
          name: "MSc Artificial Intelligence", level: "MSC", fieldOfStudy: "Computer Science",
          durationMonths: 24, tuitionFeeAmount: 19910, tuitionFeeCurrency: "EUR",
          entryRequirements: "Bachelor's degree in Artificial Intelligence, Computer Science, or a comparable quantitative field with basic computer science coursework",
          englishRequirement: "IELTS 7.0 or equivalent",
          applicationDeadline: new Date("2027-04-01"), scholarshipsAvailable: "Amsterdam Merit Scholarship",
          campus: "Science Park Campus, Amsterdam", startDates: ["September 2026"], casAvailable: false,
          dependantsPolicy: "Family reunification possible under Dutch residence permit rules",
          visaInfo: "Dutch entry visa/residence permit required for most non-EU/EEA students", postGradWorkRights: "Orientation Year residence permit — up to 12 months",
          intakeCycle: "2026/27", isNextIntake: true,
        },
      },
      {
        university: { name: "RWTH Aachen University", countryIso: "DE", city: "Aachen", type: "Public", websiteUrl: "https://www.rwth-aachen.de" },
        programme: {
          name: "MSc Data Science", level: "MSC", fieldOfStudy: "Data Science",
          durationMonths: 24, tuitionFeeAmount: 0, tuitionFeeCurrency: "EUR",
          entryRequirements: "Bachelor's degree in Computer Science, Mathematics, Physics, or a related field; GRE General Test required",
          englishRequirement: "IELTS 6.5 or TOEFL iBT 95",
          applicationDeadline: new Date("2027-03-01"), scholarshipsAvailable: "DAAD scholarships for select nationalities",
          campus: "RWTH Aachen Campus", startDates: ["October 2026"], casAvailable: false,
          dependantsPolicy: "Family reunification possible under German residence permit rules",
          visaInfo: "German national (D) visa for study purposes required for most non-EU nationals; tuition-free (semester contribution ~€298 applies)",
          postGradWorkRights: "18-month job-seeker residence permit after graduation",
          intakeCycle: "2026/27", isNextIntake: true,
        },
      },
      {
        university: { name: "Coventry University", countryIso: "GB", city: "Coventry", type: "Technological University", websiteUrl: "https://www.coventry.ac.uk" },
        programme: {
          name: "MSc Data Science", level: "MSC", fieldOfStudy: "Data Science",
          durationMonths: 12, tuitionFeeAmount: 18600, tuitionFeeCurrency: "GBP",
          entryRequirements: "2:2 honours degree or above (any discipline) or equivalent; relevant professional experience also considered",
          englishRequirement: "IELTS 6.5 overall, no component below 5.5",
          applicationDeadline: new Date("2027-06-30"), scholarshipsAvailable: "Vice-Chancellor Postgraduate Scholarship (£2,000–£3,000); 25% alumni discount",
          campus: "Coventry University Campus", startDates: ["September 2026", "January 2027"], casAvailable: true,
          dependantsPolicy: "Postgraduate taught students generally cannot bring dependants under current UK visa rules",
          visaInfo: "Student Route visa required", postGradWorkRights: "Graduate Route — 2 years post-study work visa",
          intakeCycle: "2026/27", isNextIntake: true,
        },
      },
    ];

    const created = [];
    const skipped = [];

    for (const item of additions) {
      const country = byIso[item.university.countryIso];
      if (!country) {
        skipped.push(`${item.university.name} (country ${item.university.countryIso} not found)`);
        continue;
      }

      let uni = await prisma.university.findFirst({ where: { name: item.university.name } });
      if (!uni) {
        uni = await prisma.university.create({
          data: { ...item.university, countryId: country.id, countryIso: undefined },
        });
      }

      const existingProgramme = await prisma.programme.findFirst({
        where: { universityId: uni.id, name: item.programme.name },
      });
      if (!existingProgramme) {
        await prisma.programme.create({ data: { ...item.programme, universityId: uni.id } });
        created.push(item.university.name);
      } else {
        skipped.push(`${item.university.name} (already exists)`);
      }
    }

    return res.json({ message: "Done.", created, skipped });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

app.get("/admin/backfill-faculty", async (req, res) => {
  try {
    if (!process.env.SEED_TOKEN || req.query.token !== process.env.SEED_TOKEN) {
      return res.status(403).json({ error: "Invalid or missing token" });
    }

    const prisma = require("./config/db");
    // Real school/faculty names for the 10 existing programmes (all
    // Computer Science/Data Science ones seeded so far). Safe to re-run —
    // just overwrites with the same values each time.
    const facultyByUniversity = {
      "University of Manchester": "Department of Computer Science",
      "Dublin City University": "School of Computing",
      "Technical University of Munich": "School of Computation, Information and Technology",
      "University of Edinburgh": "School of Informatics",
      "University College Dublin": "School of Computer Science",
      "Delft University of Technology": "Faculty of Electrical Engineering, Mathematics and Computer Science",
      "KTH Royal Institute of Technology": "School of Electrical Engineering and Computer Science",
      "University of Amsterdam": "Faculty of Science",
      "RWTH Aachen University": "Faculty of Mathematics, Computer Science and Natural Sciences",
      "Coventry University": "School of Computing, Electronics and Mathematics",
    };

    const universities = await prisma.university.findMany({ include: { programmes: true } });
    let updated = 0;
    for (const uni of universities) {
      const faculty = facultyByUniversity[uni.name];
      if (!faculty) continue;
      for (const p of uni.programmes) {
        if (!p.faculty) {
          await prisma.programme.update({ where: { id: p.id }, data: { faculty } });
          updated++;
        }
      }
    }

    return res.json({ message: "Done.", updated });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

app.get("/admin/seed-more2", async (req, res) => {
  try {
    if (!process.env.SEED_TOKEN || req.query.token !== process.env.SEED_TOKEN) {
      return res.status(403).json({ error: "Invalid or missing token" });
    }

    const prisma = require("./config/db");

    // 5 more real programmes from different faculties at universities we
    // already have, so the "group by faculty" UI has something to show.
    // Researched from official/aggregator sources mid-2026 — verify
    // against official pages before treating as final for real applicants.
    const additions = [
      {
        universityName: "University of Manchester",
        programme: {
          name: "MSc Business Analytics and Artificial Intelligence", faculty: "Alliance Manchester Business School",
          level: "MSC", fieldOfStudy: "Business Analytics", durationMonths: 12,
          tuitionFeeAmount: 35700, tuitionFeeCurrency: "GBP",
          entryRequirements: "First or upper second-class honours degree (2:1) from a UK university or overseas equivalent in a quantitative subject such as mathematics, statistics, physics, engineering, computing, or economics",
          englishRequirement: "IELTS 6.5 overall, minimum 6.0 in each component",
          applicationDeadline: new Date("2027-07-05"), scholarshipsAvailable: "Alliance MBS Master's scholarships (announced per cycle)",
          campus: "Alliance Manchester Business School", startDates: ["September 2026"], casAvailable: true,
          dependantsPolicy: "Postgraduate taught students generally cannot bring dependants under current UK visa rules",
          visaInfo: "Student Route visa required", postGradWorkRights: "Graduate Route — 2 years post-study work visa",
          intakeCycle: "2026/27", isNextIntake: true,
        },
      },
      {
        universityName: "University College Dublin",
        programme: {
          name: "MSc in Management", faculty: "UCD Michael Smurfit Graduate Business School",
          level: "MSC", fieldOfStudy: "Management", durationMonths: 12,
          tuitionFeeAmount: 22600, tuitionFeeCurrency: "EUR",
          entryRequirements: "Bachelor's degree (2:1 or equivalent) in any non-business discipline — designed for graduates without a business background",
          englishRequirement: "IELTS 6.5 overall, no component below 6.0",
          applicationDeadline: new Date("2027-05-01"), scholarshipsAvailable: "UCD Smurfit alumni discount (5%) where applicable",
          campus: "UCD Michael Smurfit Graduate Business School, Blackrock", startDates: ["September 2026"], casAvailable: false,
          dependantsPolicy: "Not generally applicable for non-EEA postgraduate students on a Stamp 2 permission",
          visaInfo: "Irish study visa/preclearance required for many nationalities", postGradWorkRights: "Third Level Graduate Scheme — up to 24 months stay-back",
          intakeCycle: "2026/27", isNextIntake: true,
        },
      },
      {
        universityName: "Delft University of Technology",
        programme: {
          name: "MSc Industrial Design Engineering", faculty: "Faculty of Industrial Design Engineering",
          level: "MSC", fieldOfStudy: "Design Engineering", durationMonths: 24,
          tuitionFeeAmount: 25633, tuitionFeeCurrency: "EUR",
          entryRequirements: "Bachelor's degree in industrial design, engineering, or a related field; portfolio demonstrating design/prototyping ability required",
          englishRequirement: "IELTS 7.0 or TOEFL iBT 100",
          applicationDeadline: new Date("2027-04-01"), scholarshipsAvailable: "Justus & Louise van Effen Excellence Scholarship; Holland Scholarship (€5,000)",
          campus: "TU Delft Campus", startDates: ["September 2026"], casAvailable: false,
          dependantsPolicy: "Family reunification possible under Dutch residence permit rules",
          visaInfo: "Dutch entry visa/residence permit (MVV) required for most non-EU/EEA students", postGradWorkRights: "Orientation Year residence permit — up to 12 months to find work",
          intakeCycle: "2026/27", isNextIntake: true,
        },
      },
      {
        universityName: "KTH Royal Institute of Technology",
        programme: {
          name: "MSc Industrial Management", faculty: "School of Industrial Engineering and Management",
          level: "MSC", fieldOfStudy: "Industrial Management", durationMonths: 24,
          tuitionFeeAmount: 180000, tuitionFeeCurrency: "SEK",
          entryRequirements: "Bachelor's degree with an engineering background from an internationally recognised university",
          englishRequirement: "IELTS 6.5 overall or TOEFL 90 (Swedish upper-secondary English 6 equivalent)",
          applicationDeadline: new Date("2027-01-15"), scholarshipsAvailable: "KTH Scholarship; Swedish Institute Scholarships (select countries)",
          campus: "KTH Campus, Stockholm", startDates: ["August 2026"], casAvailable: false,
          dependantsPolicy: "Family reunification permit available for spouse/children",
          visaInfo: "Swedish residence permit for studies required for non-EU/EEA students", postGradWorkRights: "12-month post-study residence permit to seek work",
          intakeCycle: "2026/27", isNextIntake: true,
        },
      },
      {
        universityName: "Technical University of Munich",
        programme: {
          name: "MSc Management", faculty: "TUM School of Management",
          level: "MSC", fieldOfStudy: "Management", durationMonths: 24,
          tuitionFeeAmount: 8000, tuitionFeeCurrency: "EUR",
          entryRequirements: "Bachelor's degree in natural sciences, engineering, or life sciences; admission-restricted with a required aptitude assessment",
          englishRequirement: "IELTS 6.5 or TOEFL iBT 88 (programme partly taught in English)",
          applicationDeadline: new Date("2027-05-31"), scholarshipsAvailable: "TUM Master's scholarships (merit-based, limited availability)",
          campus: "TUM Campus, Munich", startDates: ["October 2026"], casAvailable: false,
          dependantsPolicy: "Family reunification possible under German residence permit rules",
          visaInfo: "German national (D) visa for study purposes required for most non-EU nationals", postGradWorkRights: "18-month job-seeker residence permit after graduation",
          intakeCycle: "2026/27", isNextIntake: true,
        },
      },
    ];

    const created = [];
    const skipped = [];

    for (const item of additions) {
      const uni = await prisma.university.findFirst({ where: { name: item.universityName } });
      if (!uni) {
        skipped.push(`${item.universityName} (university not found)`);
        continue;
      }
      const existing = await prisma.programme.findFirst({
        where: { universityId: uni.id, name: item.programme.name },
      });
      if (existing) {
        skipped.push(`${item.universityName} — ${item.programme.name} (already exists)`);
        continue;
      }
      await prisma.programme.create({ data: { ...item.programme, universityId: uni.id } });
      created.push(`${item.universityName} — ${item.programme.name}`);
    }

    return res.json({ message: "Done.", created, skipped });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

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
app.use("/api/consultants", consultantRoutes);

app.use(errorHandler);

const PORT = process.env.PORT || 4000;
app.listen(PORT, () => console.log(`SGEC API listening on port ${PORT}`));