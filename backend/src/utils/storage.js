const fs = require("fs");
const path = require("path");
const { v4: uuid } = require("uuid");

const driver = process.env.STORAGE_DRIVER || "local";
const localDir = process.env.LOCAL_STORAGE_DIR || "./uploads";

if (driver === "local" && !fs.existsSync(localDir)) {
  fs.mkdirSync(localDir, { recursive: true });
}

/**
 * Saves an uploaded file buffer and returns a URL/pointer the rest of the
 * app can treat as opaque. Swap the body of this function for an S3
 * putObject call (with a private ACL + signed GET URLs) before production —
 * documents like passports and transcripts must never sit on the API
 * server's own disk in production, and must be encrypted at rest.
 *
 * TODO (production hardening):
 *  - virus-scan the buffer (e.g. ClamAV) before persisting
 *  - encrypt at rest (S3 SSE-KMS or equivalent)
 *  - generate short-lived signed URLs for reads, never public URLs
 */
async function saveFile(buffer, originalName, mimeType) {
  if (driver === "s3") {
    // TODO: implement with @aws-sdk/client-s3
    throw new Error("S3 storage driver not implemented yet — see utils/storage.js");
  }

  const ext = path.extname(originalName);
  const key = `${uuid()}${ext}`;
  const fullPath = path.join(localDir, key);
  fs.writeFileSync(fullPath, buffer);

  return {
    url: `/uploads/${key}`, // served statically in dev; replace with signed URL in prod
    key,
  };
}

module.exports = { saveFile };
