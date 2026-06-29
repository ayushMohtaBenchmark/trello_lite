# Rate limiting & abuse protection. Backed by Rails.cache (Solid Cache in
# production). Disabled in the test environment except where specs opt in.
class Rack::Attack
  Rack::Attack.enabled = !Rails.env.test?

  # Identify clients by access-token subject when present, else by IP.
  def self.client_id(req)
    auth = req.get_header("HTTP_AUTHORIZATION")
    if auth&.start_with?("Bearer ")
      payload = JsonWebToken.decode(auth.split(" ", 2).last)
      return "user:#{payload[:sub]}" if payload && payload[:sub]
    end
    "ip:#{req.ip}"
  end

  # General API throttle: 300 requests / minute per client.
  throttle("api/general", limit: ENV.fetch("RATE_LIMIT_RPM", 300).to_i, period: 60) do |req|
    client_id(req) if req.path.start_with?("/api/")
  end

  # Stricter throttle on auth endpoints to slow credential stuffing: 10 / minute / IP.
  throttle("api/auth", limit: ENV.fetch("AUTH_RATE_LIMIT_RPM", 10).to_i, period: 60) do |req|
    req.ip if req.path.start_with?("/api/v1/auth/") && req.post?
  end

  # JSON 429 with rate-limit headers.
  self.throttled_responder = lambda do |request|
    match = request.env["rack.attack.match_data"] || {}
    now = Time.now.to_i
    period = match[:period].to_i
    headers = {
      "Content-Type" => "application/json",
      "RateLimit-Limit" => match[:limit].to_s,
      "RateLimit-Remaining" => "0",
      "Retry-After" => (period - (now % [period, 1].max)).to_s
    }
    body = { error: { code: "rate_limited", message: "Too many requests. Slow down." } }
    [429, headers, [body.to_json]]
  end
end
