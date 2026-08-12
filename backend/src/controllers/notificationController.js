const prisma = require("../config/db");

async function listMine(req, res, next) {
  try {
    const notifications = await prisma.notification.findMany({
      where: { userId: req.user.id },
      orderBy: { createdAt: "desc" },
      take: 100,
    });
    return res.json(notifications);
  } catch (err) {
    next(err);
  }
}

async function markRead(req, res, next) {
  try {
    const notification = await prisma.notification.update({
      where: { id: req.params.id },
      data: { isRead: true },
    });
    return res.json(notification);
  } catch (err) {
    next(err);
  }
}

/**
 * Internal helper (not a route) other controllers can call to create a
 * notification, e.g. notify(studentUserId, "Application submitted", "...").
 * TODO: also push via FCM/APNs here once push is wired up.
 */
async function notify(userId, title, body) {
  return prisma.notification.create({ data: { userId, title, body } });
}

module.exports = { listMine, markRead, notify };
