require "net/http"
require "openssl"

module Webhooks
  # Performs a single HMAC-signed HTTP POST for a WebhookDelivery and records the
  # outcome. Raises DeliveryError on non-2xx so the job can retry.
  class Sender
    class DeliveryError < StandardError; end

    OPEN_TIMEOUT = 5
    READ_TIMEOUT = 5

    def initialize(delivery)
      @delivery = delivery
      @webhook = delivery.webhook
    end

    def call
      body = request_body
      response = post(body)
      record_result(response)
    end

    private

    def request_body
      JSON.generate(
        event: @delivery.event,
        webhook_id: @webhook.id,
        delivered_at: Time.current.iso8601,
        data: @delivery.payload
      )
    end

    def post(body)
      uri = URI.parse(@webhook.url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = OPEN_TIMEOUT
      http.read_timeout = READ_TIMEOUT

      request = Net::HTTP::Post.new(uri.request_uri)
      request["Content-Type"] = "application/json"
      request["User-Agent"] = "TrelloLite-Webhook/1.0"
      request["X-TrelloLite-Event"] = @delivery.event
      request["X-TrelloLite-Signature"] = signature(body)
      request.body = body

      http.request(request)
    end

    # HMAC-SHA256 of the raw body using the webhook's secret. Consumers verify
    # this against the same secret to authenticate the payload.
    def signature(body)
      "sha256=" + OpenSSL::HMAC.hexdigest("SHA256", @webhook.secret, body)
    end

    def record_result(response)
      code = response.code.to_i
      @delivery.update!(
        attempts: @delivery.attempts + 1,
        response_code: code,
        response_body: response.body.to_s.first(1_000)
      )

      if code.between?(200, 299)
        @delivery.update!(status: :delivered, delivered_at: Time.current)
      else
        @delivery.update!(status: :failed)
        raise DeliveryError, "Webhook #{@webhook.id} responded with HTTP #{code}"
      end
    end
  end
end
