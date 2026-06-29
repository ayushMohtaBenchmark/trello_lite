# Thin wrapper around the `jwt` gem for HS256 access tokens.
class JsonWebToken
  ALGORITHM = "HS256".freeze

  class << self
    def encode(payload, exp: 30.minutes.from_now)
      claims = payload.dup
      claims[:exp] = exp.to_i
      claims[:iat] = Time.current.to_i
      JWT.encode(claims, secret_key, ALGORITHM)
    end

    # Returns a symbolized claims hash, or nil if the token is invalid/expired.
    def decode(token)
      payload, = JWT.decode(token, secret_key, true, algorithm: ALGORITHM)
      payload.deep_symbolize_keys
    rescue JWT::DecodeError
      nil
    end

    def secret_key
      ENV["JWT_SECRET_KEY"].presence || Rails.application.secret_key_base
    end
  end
end
