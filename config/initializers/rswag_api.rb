Rswag::Api.configure do |c|
  # Serve the OpenAPI documents from this folder at /api-docs.
  c.openapi_root = Rails.root.join("swagger").to_s
end
