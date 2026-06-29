module AuthHelpers
  # Bearer auth headers for a user (default content type JSON).
  def auth_headers(user, content_type: "application/json")
    token = Auth::TokenIssuer.issue_for(user).access_token
    { "Authorization" => "Bearer #{token}", "CONTENT_TYPE" => content_type }
  end

  def json_headers
    { "CONTENT_TYPE" => "application/json", "ACCEPT" => "application/json" }
  end
end
