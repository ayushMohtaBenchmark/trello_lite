# Error tracking. No-op unless SENTRY_DSN is set, so dev/test stay quiet.
if ENV["SENTRY_DSN"].present?
  Sentry.init do |config|
    config.dsn = ENV["SENTRY_DSN"]
    config.breadcrumbs_logger = %i[active_support_logger http_logger]
    config.environment = Rails.env
    config.release = ENV["GIT_SHA"]
    config.traces_sample_rate = ENV.fetch("SENTRY_TRACES_SAMPLE_RATE", "0.1").to_f
    config.send_default_pii = false
    # Don't report routine 4xx client errors as exceptions.
    config.excluded_exceptions += %w[
      ActiveRecord::RecordNotFound
      ActionController::ParameterMissing
      Pundit::NotAuthorizedError
    ]
  end
end
