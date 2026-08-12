const express = require("express");
const router = express.Router();
const controller = require("../controllers/universityController");
const { requireAuth, requireRole } = require("../middleware/auth");

// Browsing is available to any authenticated user (student/consultant/admin).
router.get("/", requireAuth, controller.list);
router.get("/:id", requireAuth, controller.detail);

// Only admins manage the catalog itself.
router.post("/", requireAuth, requireRole("ADMIN"), controller.create);
router.put("/:id", requireAuth, requireRole("ADMIN"), controller.update);
router.delete("/:id", requireAuth, requireRole("ADMIN"), controller.remove);

module.exports = router;
