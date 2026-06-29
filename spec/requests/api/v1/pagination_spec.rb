require "rails_helper"

RSpec.describe "Pagination", type: :request do
  let(:user) { create(:user) }

  before { create_list(:board, 30, owner: user) }

  it "honours per_page and exposes page metadata headers" do
    get "/api/v1/boards", params: { per_page: 10, page: 2 }, headers: auth_headers(user)
    expect(response).to have_http_status(:ok)
    expect(json.size).to eq(10)
    expect(response.headers["X-Total-Count"]).to eq("30")
    expect(response.headers["X-Total-Pages"]).to eq("3")
    expect(response.headers["Link"]).to include('rel="next"')
  end

  it "returns 422 for an out-of-range page" do
    get "/api/v1/boards", params: { per_page: 10, page: 99 }, headers: auth_headers(user)
    expect(response).to have_http_status(:unprocessable_entity)
    expect(json.dig("error", "code")).to eq("page_out_of_range")
  end
end
