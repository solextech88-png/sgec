const express = require("express");
const multer = require("multer");
const router = express.Router();
const controller = require("../controllers/documentController");
const { requireAuth, requireRole } = require("../middleware/auth");

// Keep files in memory briefly, then hand off to the storage adapter.
// 15MB cap — tune per document type if needed (photos vs. large PDFs).
const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 15 * 1024 * 1024 } });

router.post("/", requireAuth, requireRole("STUDENT"), upload.single("file"), controller.upload);
router.get("/mine", requireAuth, requireRole("STUDENT"), controller.listMine);
router.delete("/:id", requireAuth, requireRole("STUDENT"), controller.remove);
router.put("/:id/verify", requireAuth, requireRole("CONSULTANT", "ADMIN"), controller.verify);

module.exports = router;
