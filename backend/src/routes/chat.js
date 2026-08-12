const express = require("express");
const router = express.Router();
const controller = require("../controllers/chatController");
const { requireAuth } = require("../middleware/auth");

router.get("/thread", requireAuth, controller.getOrCreateThread);
router.get("/thread/:threadId/messages", requireAuth, controller.listMessages);
router.post("/thread/:threadId/messages", requireAuth, controller.sendMessage);

module.exports = router;
