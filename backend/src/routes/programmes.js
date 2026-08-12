const express = require("express");
const router = express.Router();
const controller = require("../controllers/programmeController");
const { requireAuth, requireRole } = require("../middleware/auth");

router.get("/", requireAuth, controller.list);
router.get("/:id", requireAuth, controller.detail);

router.post("/", requireAuth, requireRole("ADMIN"), controller.create);
router.put("/:id", requireAuth, requireRole("ADMIN"), controller.update);
router.delete("/:id", requireAuth, requireRole("ADMIN"), controller.remove);

module.exports = router;
