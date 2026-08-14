const express = require("express");
const router = express.Router();
const controller = require("../controllers/applicationController");
const { requireAuth, requireRole } = require("../middleware/auth");

router.post("/", requireAuth, requireRole("STUDENT"), controller.createDraft);
router.get("/mine", requireAuth, requireRole("STUDENT"), controller.listMine);
router.put("/:id/withdraw", requireAuth, requireRole("STUDENT"), controller.withdraw);

router.get("/", requireAuth, requireRole("CONSULTANT", "ADMIN"), controller.listAll);
router.put("/:id/status", requireAuth, requireRole("CONSULTANT", "ADMIN"), controller.updateStatus);
router.post("/:id/submit", requireAuth, requireRole("CONSULTANT", "ADMIN"), controller.submitToUniversity);

module.exports = router;
