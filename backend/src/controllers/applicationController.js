const prisma = require("../config/db");

async function createDraft(req, res, next) {
  try {
    const { programmeId } = req.body;
    const student = await prisma.studentProfile.findUnique({ where: { userId: req.user.id } });
    if (!student) return res.status(404).json({ error: "Student profile not found" });

    // Require at least one SIGNED, non-revoked consent before allowing any
    // application to be created — this is the enforcement point for the
    // "student authorizes the consultancy to act on their behalf" rule.
    const hasValidConsent = await prisma.consentSignature.findFirst({
      where: { studentId: student.id, status: "SIGNED" },
    });
    if (!hasValidConsent) {
      return res.status(403).json({
        error: "A signed consent form is required before creating an application",
      });
    }

    const application = await prisma.application.create({
      data: {
        studentId: student.id,
        programmeId,
        status: "DRAFT",
        statusHistory: { create: { status: "DRAFT" } },
      },
      include: { programme: true },
    });
    return res.status(201).json(application);
  } catch (err) {
    next(err);
  }
}

async function listMine(req, res, next) {
  try {
    const student = await prisma.studentProfile.findUnique({ where: { userId: req.user.id } });
    const applications = await prisma.application.findMany({
      where: { studentId: student.id },
      include: { programme: { include: { university: true } } },
      orderBy: { createdAt: "desc" },
    });
    return res.json(applications);
  } catch (err) {
    next(err);
  }
}

// Consultant/Admin: view + advance any application
async function listAll(req, res, next) {
  try {
    const { status, consultantId } = req.query;
    const where = {};
    if (status) where.status = status;
    if (consultantId) where.student = { assignedConsultantId: consultantId };

    const applications = await prisma.application.findMany({
      where,
      include: {
        student: { include: { user: { select: { email: true } } } },
        programme: { include: { university: true } },
      },
      orderBy: { updatedAt: "desc" },
    });
    return res.json(applications);
  } catch (err) {
    next(err);
  }
}

async function updateStatus(req, res, next) {
  try {
    const { status, note } = req.body;
    const application = await prisma.application.update({
      where: { id: req.params.id },
      data: {
        status,
        submittedAt: status === "SUBMITTED" ? new Date() : undefined,
        decisionAt: ["OFFER_CONDITIONAL", "OFFER_UNCONDITIONAL", "REJECTED"].includes(status)
          ? new Date()
          : undefined,
        statusHistory: { create: { status, note } },
      },
    });
    return res.json(application);
  } catch (err) {
    next(err);
  }
}

/**
 * TODO: Real submission integration.
 * For universities with hasIntegratedApi=true, this is where you'd call
 * that university's (or a shared platform's, e.g. UCAS-style) submission
 * API with the compiled application payload + documents. For everyone
 * else, "submission" today means a consultant manually completes the
 * university's own portal, then marks status=SUBMITTED here. Start with
 * the handful of partner universities that actually expose an API and
 * fall back to manual for the rest — don't try to build all integrations
 * before launch.
 */
async function submitToUniversity(req, res, next) {
  return res.status(501).json({
    error: "Automated per-university submission not implemented — see TODO in applicationController.js",
  });
}

/**
 * Lets a student withdraw their own application at any point before it
 * reaches a terminal state. Ownership is enforced by matching studentId
 * against the caller's own student profile, not just the application id —
 * without that check any student could withdraw any application by guessing
 * an id. Already-terminal applications (withdrawn, rejected, enrolled) can't
 * be withdrawn again; that's not a real action, just noise in the history.
 */
const TERMINAL_STATUSES = ["WITHDRAWN", "REJECTED", "ENROLLED"];

async function withdraw(req, res, next) {
  try {
    const student = await prisma.studentProfile.findUnique({ where: { userId: req.user.id } });
    if (!student) return res.status(404).json({ error: "Student profile not found" });

    const application = await prisma.application.findUnique({ where: { id: req.params.id } });
    if (!application || application.studentId !== student.id) {
      return res.status(404).json({ error: "Application not found" });
    }
    if (TERMINAL_STATUSES.includes(application.status)) {
      return res.status(400).json({ error: `Cannot withdraw an application that is already ${application.status}` });
    }

    const updated = await prisma.application.update({
      where: { id: application.id },
      data: {
        status: "WITHDRAWN",
        statusHistory: { create: { status: "WITHDRAWN", note: "Withdrawn by student" } },
      },
    });
    return res.json(updated);
  } catch (err) {
    next(err);
  }
}

module.exports = { createDraft, listMine, listAll, updateStatus, submitToUniversity, withdraw };
