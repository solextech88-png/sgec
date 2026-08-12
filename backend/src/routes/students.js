const express = require("express");
const router = express.Router();
const controller = require("../controllers/studentController");
const { requireAuth, requireRole } = require("../middleware/auth");

// Self-service
router.get("/me", requireAuth, requireRole("STUDENT"), controller.getMyProfile);
router.put("/me", requireAuth, requireRole("STUDENT"), controller.updateMyProfile);

// Consultant/Admin management
router.get("/", requireAuth, requireRole("CONSULTANT", "ADMIN"), controller.listAll);
router.get("/:id", requireAuth, requireRole("CONSULTANT", "ADMIN"), controller.getById);
router.put("/:id/assign-consultant", requireAuth, requireRole("ADMIN"), controller.assignConsultant);

module.exports = router;
