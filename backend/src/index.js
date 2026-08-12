require("dotenv").config();
const express = require("express");
const cors = require("cors");
const helmet = require("helmet");
const path = require("path");

const errorHandler = require("./middleware/errorHandler");

const authRoutes = require("./routes/auth");
const studentRoutes = require("./routes/students");
const documentRoutes = require("./routes/documents");
const consentRoutes = require("./routes/consent");
const countryRoutes = require("./routes/countries");
const universityRoutes = require("./routes/universities");
const programmeRoutes = require("./routes/programmes");
const applicationRoutes = require("./routes/applications");
const chatRoutes = require("./routes/chat");
const notificationRoutes = require("./routes/notifications");
const aiRoutes = require("./routes/ai");

const app = express();

app.use(helmet());
app.use(cors()); // TODO: restrict origins before production
app.use(express.json({ limit: "2mb" }));

// Serves locally-stored uploads in dev only. In production, swap the
// storage driver to S3 and remove this — documents should be served via
// short-lived signed URLs, never a public static route.
if (process.env.STORAGE_DRIVER !== "s3") {
  app.use("/uploads", express.static(path.join(__dirname, "..", process.env.LOCAL_STORAGE_DIR || "uploads")));
}

app.get("/health", (req, res) => res.json({ status: "ok" }));

app.use("/api/auth", authRoutes);
app.use("/api/students", studentRoutes);
app.use("/api/documents", documentRoutes);
app.use("/api/consent", consentRoutes);
app.use("/api/countries", countryRoutes);
app.use("/api/universities", universityRoutes);
app.use("/api/programmes", programmeRoutes);
app.use("/api/applications", applicationRoutes);
app.use("/api/chat", chatRoutes);
app.use("/api/notifications", notificationRoutes);
app.use("/api/ai", aiRoutes);

app.use(errorHandler);

const PORT = process.env.PORT || 4000;
app.listen(PORT, () => console.log(`SGEC API listening on port ${PORT}`));
