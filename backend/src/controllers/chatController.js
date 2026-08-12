const prisma = require("../config/db");

// NOTE: This is a simple REST/polling implementation to get the mobile app
// working end-to-end quickly. For a production-grade real-time feel,
// replace with Socket.IO or a managed service (Firebase, Pusher) — keep
// the same request/response shapes so the Flutter chat screen doesn't need
// to change, just how messages arrive.

async function getOrCreateThread(req, res, next) {
  try {
    const student = await prisma.studentProfile.findUnique({ where: { userId: req.user.id } });
    let thread = await prisma.chatThread.findFirst({ where: { studentId: student.id } });
    if (!thread) {
      thread = await prisma.chatThread.create({ data: { studentId: student.id } });
    }
    return res.json(thread);
  } catch (err) {
    next(err);
  }
}

async function listMessages(req, res, next) {
  try {
    const messages = await prisma.chatMessage.findMany({
      where: { threadId: req.params.threadId },
      orderBy: { createdAt: "asc" },
    });
    return res.json(messages);
  } catch (err) {
    next(err);
  }
}

async function sendMessage(req, res, next) {
  try {
    const { body } = req.body;
    const message = await prisma.chatMessage.create({
      data: { threadId: req.params.threadId, senderId: req.user.id, body },
    });
    return res.status(201).json(message);
  } catch (err) {
    next(err);
  }
}

module.exports = { getOrCreateThread, listMessages, sendMessage };
