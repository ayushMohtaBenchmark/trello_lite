module Auth
  # Issues short-lived JWT access tokens paired with opaque, rotating refresh
  # tokens. Refresh tokens are stored only as SHA-256 digests.
  class TokenIssuer
    ACCESS_TTL  = 30.minutes
    REFRESH_TTL = 30.days

    Tokens = Struct.new(:access_token, :refresh_token, :expires_in, keyword_init: true)

    def self.issue_for(user)
      access = JsonWebToken.encode({ sub: user.id }, exp: ACCESS_TTL.from_now)
      raw    = SecureRandom.urlsafe_base64(48)
      user.refresh_tokens.create!(token_digest: digest(raw), expires_at: REFRESH_TTL.from_now)

      Tokens.new(access_token: access, refresh_token: raw, expires_in: ACCESS_TTL.to_i)
    end

    # Validates and one-time-uses a refresh token, returning a fresh pair.
    def self.rotate(raw_refresh)
      record = RefreshToken.active.find_by(token_digest: digest(raw_refresh.to_s))
      return nil unless record

      record.revoke!
      issue_for(record.user)
    end

    def self.revoke(raw_refresh)
      RefreshToken.active.find_by(token_digest: digest(raw_refresh.to_s))&.revoke!
    end

    def self.digest(raw)
      Digest::SHA256.hexdigest(raw)
    end
  end
end
