const { PrismaClient } = require("@prisma/client");
const prisma = new PrismaClient();

// Small realistic sample so the app works out of the box. Replace/extend
// via the admin portal or a bulk import job — see README for the plan on
// keeping the full UK/Ireland/Europe catalog current annually.

async function main() {
  const countries = await Promise.all(
    [
      { name: "United Kingdom", isoCode: "GB", region: "UK" },
      { name: "Ireland", isoCode: "IE", region: "Ireland" },
      { name: "Germany", isoCode: "DE", region: "Europe" },
      { name: "Netherlands", isoCode: "NL", region: "Europe" },
      { name: "France", isoCode: "FR", region: "Europe" },
      { name: "Poland", isoCode: "PL", region: "Europe" },
      { name: "Sweden", isoCode: "SE", region: "Europe" },
    ].map((c) =>
      prisma.country.upsert({ where: { isoCode: c.isoCode }, update: {}, create: c })
    )
  );

  const uk = countries.find((c) => c.isoCode === "GB");
  const ie = countries.find((c) => c.isoCode === "IE");
  const de = countries.find((c) => c.isoCode === "DE");

  const manchester = await prisma.university.create({
    data: {
      name: "University of Manchester",
      countryId: uk.id,
      city: "Manchester",
      type: "Public",
      websiteUrl: "https://www.manchester.ac.uk",
    },
  });

  const dcu = await prisma.university.create({
    data: {
      name: "Dublin City University",
      countryId: ie.id,
      city: "Dublin",
      type: "Public",
      websiteUrl: "https://www.dcu.ie",
    },
  });

  const tum = await prisma.university.create({
    data: {
      name: "Technical University of Munich",
      countryId: de.id,
      city: "Munich",
      type: "Public",
      websiteUrl: "https://www.tum.de",
    },
  });

  await prisma.programme.createMany({
    data: [
      {
        universityId: manchester.id,
        name: "MSc Data Science",
        level: "MSC",
        fieldOfStudy: "Computer Science",
        durationMonths: 12,
        tuitionFeeAmount: 28500,
        tuitionFeeCurrency: "GBP",
        entryRequirements: "2:1 UK Honours degree or international equivalent in a numerate discipline",
        englishRequirement: "IELTS 6.5 overall, no component below 6.0",
        applicationDeadline: new Date("2027-06-30"),
        scholarshipsAvailable: "International Merit Scholarship up to £5,000",
        campus: "Main Campus",
        startDates: ["September 2026", "September 2027"],
        casAvailable: true,
        dependantsPolicy: "Postgraduate taught students generally cannot bring dependants under current UK visa rules",
        visaInfo: "Student Route (Tier 4 successor) visa required",
        postGradWorkRights: "Graduate Route — 2 years post-study work visa",
        intakeCycle: "2026/27",
        isNextIntake: true,
      },
      {
        universityId: dcu.id,
        name: "MSc Artificial Intelligence",
        level: "MSC",
        fieldOfStudy: "Computer Science",
        durationMonths: 12,
        tuitionFeeAmount: 20500,
        tuitionFeeCurrency: "EUR",
        entryRequirements: "Level 8 Honours degree (2.2 or above) in a computing-related discipline",
        englishRequirement: "IELTS 6.5 overall, no component below 6.0",
        applicationDeadline: new Date("2027-07-15"),
        scholarshipsAvailable: "DCU International Excellence Scholarship",
        campus: "Glasnevin Campus",
        startDates: ["September 2026"],
        casAvailable: false,
        dependantsPolicy: "Not generally applicable for non-EEA postgraduate students on a Stamp 2 permission",
        visaInfo: "Irish study visa/preclearance required for many nationalities",
        postGradWorkRights: "Third Level Graduate Scheme — up to 2 years stay-back",
        intakeCycle: "2026/27",
        isNextIntake: true,
      },
      {
        universityId: tum.id,
        name: "MSc Mechanical Engineering",
        level: "MSC",
        fieldOfStudy: "Engineering",
        durationMonths: 24,
        tuitionFeeAmount: 0,
        tuitionFeeCurrency: "EUR",
        entryRequirements: "Bachelor's degree in Mechanical Engineering or closely related field",
        englishRequirement: "IELTS 6.5 or equivalent (English-taught track)",
        applicationDeadline: new Date("2027-05-31"),
        scholarshipsAvailable: "DAAD scholarships for select nationalities",
        campus: "Garching Campus",
        startDates: ["October 2026"],
        casAvailable: false,
        dependantsPolicy: "Family reunification possible under German residence permit rules",
        visaInfo: "German national (D) visa for study purposes required for most non-EU nationals",
        postGradWorkRights: "18-month job-seeker residence permit after graduation",
        intakeCycle: "2026/27",
        isNextIntake: true,
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

  console.log("Seed complete.");
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
