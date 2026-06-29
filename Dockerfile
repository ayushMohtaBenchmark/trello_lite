# syntax=docker/dockerfile:1
# Production image: multi-stage, slim runtime, non-root, Thruster in front of Puma.
ARG RUBY_VERSION=3.3.6
FROM ruby:$RUBY_VERSION-slim AS base

ENV RAILS_ENV=production \
    BUNDLE_DEPLOYMENT=1 \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT=development:test

WORKDIR /rails

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends curl libvips postgresql-client && \
    rm -rf /var/lib/apt/lists/*

# ---- build stage: compile gems ----
FROM base AS build

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends build-essential git libpq-dev && \
    rm -rf /var/lib/apt/lists/*

COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle "${BUNDLE_PATH}/ruby/*/cache" "${BUNDLE_PATH}/ruby/*/bundler/gems/*/.git" && \
    bundle exec bootsnap precompile --gemfile

COPY . .
RUN bundle exec bootsnap precompile app/ lib/

# ---- final runtime image ----
FROM base

COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

# Run as an unprivileged user.
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails /rails db log storage tmp
USER 1000:1000

ENTRYPOINT ["/rails/bin/docker-entrypoint"]

EXPOSE 80
# Thruster terminates HTTP and forwards to Puma.
CMD ["./bin/thrust", "./bin/rails", "server"]
