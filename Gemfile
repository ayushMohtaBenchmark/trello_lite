source "https://rubygems.org"

ruby "3.3.6"

# --- Core ---------------------------------------------------------------
gem "rails", "~> 8.1.3"
gem "pg", "~> 1.5"
gem "puma", ">= 6.4"

# --- Authentication & Authorization ------------------------------------
gem "bcrypt", "~> 3.1"          # has_secure_password
gem "jwt", "~> 2.9"             # access tokens
gem "pundit", "~> 2.4"          # policy-based authorization

# --- API presentation ---------------------------------------------------
gem "alba", "~> 3.5"            # serializers
gem "oj", "~> 3.16"            # fast JSON backend for Alba
gem "pagy", "~> 9.3"           # pagination
gem "rack-attack", "~> 6.7"    # rate limiting / throttling
gem "rack-cors", "~> 2.0"      # CORS

# --- API documentation (OpenAPI / Swagger UI) --------------------------
gem "rswag-api", "~> 2.16"
gem "rswag-ui", "~> 2.16"

# --- Background jobs & cache (DB-backed; no Redis) ----------------------
gem "solid_queue", "~> 1.1"
gem "solid_cache", "~> 1.0"

# --- File uploads -------------------------------------------------------
gem "image_processing", "~> 1.13"  # Active Storage variants
gem "aws-sdk-s3", "~> 1.0", require: false  # production object storage

# --- Observability ------------------------------------------------------
gem "sentry-ruby", "~> 5.21"
gem "sentry-rails", "~> 5.21"

# --- Boot / runtime -----------------------------------------------------
gem "bootsnap", require: false
gem "thruster", require: false
gem "tzinfo-data", platforms: %i[windows jruby]

group :development, :test do
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"
  gem "dotenv-rails"
  gem "rspec-rails", "~> 7.1"
  gem "factory_bot_rails", "~> 6.4"
  gem "faker", "~> 3.5"
  gem "shoulda-matchers", "~> 6.4"
  gem "bullet", "~> 8.0"            # N+1 detection (raises in test)
  gem "brakeman", require: false    # static security analysis
  gem "bundler-audit", require: false
  gem "rubocop-rails-omakase", require: false
end

group :test do
  gem "simplecov", "~> 0.22", require: false
  gem "webmock", "~> 3.24"         # stub outbound webhook calls
  gem "rswag-specs", "~> 2.16"     # request-spec → OpenAPI parity
end
