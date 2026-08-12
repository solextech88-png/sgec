const prisma = require("../config/db");
const { saveFile } = require("../utils/storage");

async function upload(req, res, next) {
  try {
    if (!req.file) return res.status(400).json({ error: "No file provided" });
    const { type } = req.body; // one of DocumentType enum values

    const student = await prisma.studentProfile.findUnique({
      where: { userId: req.user.id },
    });
    if (!student) return res.status(404).json({ error: "Student profile not found" });

    const { url } = await saveFile(req.file.buffer, req.file.originalname, req.file.mimetype);

    const document = await prisma.document.create({
      data: {
        studentId: student.id,
        type,
        fileUrl: url,
        fileName: req.file.originalname,
        mimeType: req.file.mimetype,
        sizeBytes: req.file.size,
      },
    });

    return res.status(201).json(document);
  } catch (err) {
    next(err);
  }
}

async function listMine(req, res, next) {
  try {
    const student = await prisma.studentProfile.findUnique({
      where: { userId: req.user.id },
    });
    const documents = await prisma.document.findMany({
      where: { studentId: student.id },
      orderBy: { uploadedAt: "desc" },
    });
    return res.json(documents);
  } catch (err) {
    next(err);
  }
}

async function remove(req, res, next) {
  try {
    // TODO: also delete the underlying object from storage (S3 etc.)
    await prisma.document.delete({ where: { id: req.params.id } });
    return res.status(204).send();
  } catch (err) {
    next(err);
  }
}

// Consultant marks a document reviewed/verified
async function verify(req, res, next) {
  try {
    const document = await prisma.document.update({
      where: { id: req.params.id },
      data: { verifiedByConsultant: true },
    });
    return res.json(document);
  } catch (err) {
    next(err);
  }
}

module.exports = { upload, listMine, remove, verify };
