// Catch-all error handler. Route handlers should call next(err) on failure
// rather than sending ad-hoc error responses, so logging stays consistent.
function errorHandler(err, req, res, next) {
  console.error(err);

  if (err.name === "ZodError") {
    return res.status(400).json({ error: "Validation failed", details: err.errors });
  }

  const status = err.status || 500;
  const message = status === 500 ? "Internal server error" : err.message;
  return res.status(status).json({ error: message });
}

module.exports = errorHandler;
