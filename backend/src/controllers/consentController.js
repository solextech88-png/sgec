const crypto = require("crypto");
const prisma = require("../config/db");
const { saveFile } = require("../utils/storage");

// ---- Admin: manage the consent form text itself ----

async function createForm(req, res, next) {
  try {
    const { version, title, bodyMarkdown, countryScope } = req.body;
    const form = await prisma.consentForm.create({
      data: { version, title, bodyMarkdown, countryScope },
    });
    return res.status(201).json(form);
  } catch (err) {
    next(err);
  }
}

async function listForms(req, res, next) {
  try {
    const forms = await prisma.consentForm.findMany({ orderBy: { createdAt: "desc" } });
    return res.json(forms);
  } catch (err) {
    next(err);
  }
}

// ---- Student: sign a form ----

/**
 * Records a legally-relevant signature event:
 *  - a sha256 hash of the exact bodyMarkdown the student saw, so if the
 *    text is edited later you can prove what they actually agreed to
 *  - the student's IP address and server timestamp
 *  - either a captured signature-pad image or a typed full legal name
 *
 * IMPORTANT: this establishes an audit trail, not legal validity by
 * itself. Whether this satisfies e-signature law (e.g. eIDAS in the EU,
 * ESIGN/UETA in the US, similar regimes elsewhere) depends on jurisdiction
 * and should be reviewed by a lawyer. For higher assurance, integrate a
 * qualified e-signature provider (DocuSign, HelloSign, etc.) instead of
 * relying solely on this in-house record.
 */
async function signForm(req, res, next) {
  try {
    const { consentFormId, typedFullName } = req.body;

    const form = await prisma.consentForm.findUnique({ where: { id: consentFormId } });
    if (!form) return res.status(404).json({ error: "Consent form not found" });

    const student = await prisma.studentProfile.findUnique({ where: { userId: req.user.id } });
    if (!student) return res.status(404).json({ error: "Student profile not found" });

    let signatureImageUrl = null;
    if (req.file) {
      const { url } = await saveFile(req.file.buffer, req.file.originalname, req.file.mimetype);
      signatureImageUrl = url;
    }

    const documentHash = crypto.createHash("sha256").update(form.bodyMarkdown).digest("hex");

    const signature = await prisma.consentSignature.create({
      data: {
        studentId: student.id,
        consentFormId,
        status: "SIGNED",
        signatureImageUrl,
        typedFullName,
        documentHash,
        ipAddress: req.ip,
        signedAt: new Date(),
      },
    });

    return res.status(201).json(signature);
  } catch (err) {
    next(err);
  }
}

async function myConsents(req, res, next) {
  try {
    const student = await prisma.studentProfile.findUnique({ where: { userId: req.user.id } });
    const signatures = await prisma.consentSignature.findMany({
      where: { studentId: student.id },
      include: { consentForm: true },
      orderBy: { createdAt: "desc" },
    });
    return res.json(signatures);
  } catch (err) {
    next(err);
  }
}

async function revoke(req, res, next) {
  try {
    const signature = await prisma.consentSignature.update({
      where: { id: req.params.id },
      data: { status: "REVOKED", revokedAt: new Date() },
    });
    return res.json(signature);
  } catch (err) {
    next(err);
  }
}

module.exports = { createForm, listForms, signForm, myConsents, revoke };
