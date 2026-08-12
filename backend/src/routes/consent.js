const express = require("express");
const multer = require("multer");
const router = express.Router();
const controller = require("../controllers/consentController");
const { requireAuth, requireRole } = require("../middleware/auth");

const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 5 * 1024 * 1024 } });

// Admin manages the legal text
router.post("/forms", requireAuth, requireRole("ADMIN"), controller.createForm);
router.get("/forms", requireAuth, controller.listForms);

// Student signs / views their own signatures
router.post("/sign", requireAuth, requireRole("STUDENT"), upload.single("signatureImage"), controller.signForm);
router.get("/mine", requireAuth, requireRole("STUDENT"), controller.myConsents);
router.put("/:id/revoke", requireAuth, requireRole("STUDENT"), controller.revoke);

module.exports = router;
