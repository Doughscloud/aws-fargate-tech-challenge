module.exports = {
  port: process.env.PORT || 8080,
  host: "0.0.0.0",
  // Set to your frontend ALB URL at runtime (e.g., http://<alb-dns>)
  corsAllowedOrigin: process.env.CORS_ALLOWED_ORIGIN || "*",
};
