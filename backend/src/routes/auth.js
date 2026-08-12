const express = require("express");
const rateLimit = require("express-rate-limit");
const router = express.Router();
const authController = require("../controllers/authController");

// Auth endpoints are prime brute-force/spam targets — rate limit them.
const authLimiter = rateLimit({ windowMs: 15 * 60 * 1000, max: 30 });
router.use(authLimiter);

router.post("/register", authController.register);
router.post("/login", authController.login);
router.post("/otp/send", authController.sendOtp);
router.post("/otp/confirm", authController.confirmOtp);
router.post("/social", authController.socialAuth);

module.exports = router;
