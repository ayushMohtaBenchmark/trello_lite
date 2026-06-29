# N+1 query detection. Raises in test (so CI fails on regressions) and warns in
# the development log.
if defined?(Bullet) && (Rails.env.development? || Rails.env.test?)
  Rails.application.config.after_initialize do
    Bullet.enable = true
    Bullet.bullet_logger = true
    Bullet.rails_logger = Rails.env.development?
    Bullet.raise = Rails.env.test?
  end
end
