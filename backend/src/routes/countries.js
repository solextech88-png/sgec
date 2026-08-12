const express = require("express");
const router = express.Router();
const controller = require("../controllers/countryController");
const { requireAuth, requireRole } = require("../middleware/auth");

router.get("/", requireAuth, controller.list);
router.post("/", requireAuth, requireRole("ADMIN"), controller.create);
router.put("/:id", requireAuth, requireRole("ADMIN"), controller.update);
router.delete("/:id", requireAuth, requireRole("ADMIN"), controller.remove);

module.exports = router;
