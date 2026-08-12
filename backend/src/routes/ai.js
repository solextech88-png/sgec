const express = require("express");
const router = express.Router();
const controller = require("../controllers/aiController");
const { requireAuth, requireRole } = require("../middleware/auth");

router.get("/recommend", requireAuth, requireRole("STUDENT"), controller.recommend);
router.get("/admission-chance/:programmeId", requireAuth, requireRole("STUDENT"), controller.admissionChance);
router.post("/review-document", requireAuth, requireRole("STUDENT"), controller.reviewDocument);
router.post("/chat", requireAuth, requireRole("STUDENT"), controller.chat);

module.exports = router;
