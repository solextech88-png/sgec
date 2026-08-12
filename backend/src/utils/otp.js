const prisma = require("../config/db");

function generateCode() {
  return String(Math.floor(100000 + Math.random() * 900000)); // 6 digits
}

async function issueOtp(userId, channel) {
  const code = generateCode();
  const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 min

  await prisma.otpCode.create({
    data: { userId, code, channel, expiresAt },
  });

  await deliverOtp(channel, code);
  return true;
}

/**
 * TODO: swap these console.log calls for real providers:
 * - SMS_PROVIDER=twilio -> use the Twilio Node SDK
 * - EMAIL_PROVIDER=sendgrid -> use @sendgrid/mail
 * Keeping delivery behind this one function means route code never changes.
 */
async function deliverOtp(channel, code) {
  console.log(`[OTP] Sending code ${code} via ${channel} (stubbed sender)`);
}

async function verifyOtp(userId, code) {
  const record = await prisma.otpCode.findFirst({
    where: { userId, code, consumed: false, expiresAt: { gt: new Date() } },
    orderBy: { createdAt: "desc" },
  });

  if (!record) return false;

  await prisma.otpCode.update({
    where: { id: record.id },
    data: { consumed: true },
  });
  return true;
}

module.exports = { issueOtp, verifyOtp };
