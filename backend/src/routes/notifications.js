const express = require("express");
const router = express.Router();
const controller = require("../controllers/notificationController");
const { requireAuth } = require("../middleware/auth");

router.get("/mine", requireAuth, controller.listMine);
router.put("/:id/read", requireAuth, controller.markRead);

module.exports = router;
