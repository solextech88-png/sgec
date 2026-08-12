const { PrismaClient } = require("@prisma/client");

// Reuse a single PrismaClient instance across the app (and across hot
// reloads in dev) to avoid exhausting DB connections.
const prisma = global.__sgecPrisma || new PrismaClient();
if (process.env.NODE_ENV !== "production") {
  global.__sgecPrisma = prisma;
}

module.exports = prisma;
