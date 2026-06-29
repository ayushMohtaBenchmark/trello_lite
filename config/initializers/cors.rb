# Cross-Origin Resource Sharing for the JSON API.
#
# Allowed origins are driven by the CORS_ORIGINS env var (comma-separated).
# Defaults to "*" in development so local SPA/tooling can call the API.
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins(*ENV.fetch("CORS_ORIGINS", "*").split(",").map(&:strip))

    resource "*",
      headers: :any,
      methods: %i[get post put patch delete options head],
      expose: %w[Authorization Link X-Total-Count X-Page X-Per-Page X-Total-Pages X-RateLimit-Limit X-RateLimit-Remaining Retry-After],
      max_age: 600
  end
end
