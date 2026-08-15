const express = require("express");
const router = express.Router();
const controller = require("../controllers/consultantController");
const { requireAuth, requireRole } = require("../middleware/auth");

router.get("/", requireAuth, requireRole("ADMIN", "CONSULTANT"), controller.list);
router.post("/", requireAuth, requireRole("ADMIN"), controller.create);

module.exports = router;
