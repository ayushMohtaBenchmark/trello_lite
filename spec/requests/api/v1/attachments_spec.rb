require "rails_helper"

RSpec.describe "Attachments API", type: :request do
  let(:owner) { create(:user) }
  let(:board) { create(:board, owner: owner) }
  let(:list)  { create(:list, board: board) }
  let(:card)  { create(:card, list: list, creator: owner) }

  def bearer(user)
    { "Authorization" => "Bearer #{Auth::TokenIssuer.issue_for(user).access_token}" }
  end

  let(:upload) do
    Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/sample.txt"), "text/plain")
  end

  it "uploads, lists and deletes an attachment" do
    post "/api/v1/cards/#{card.id}/attachments", params: { file: upload }, headers: bearer(owner)
    expect(response).to have_http_status(:created)
    expect(json["filename"]).to eq("sample.txt")
    attachment_id = json["id"]

    get "/api/v1/cards/#{card.id}/attachments", headers: bearer(owner)
    expect(json.size).to eq(1)

    delete "/api/v1/attachments/#{attachment_id}", headers: bearer(owner)
    expect(response).to have_http_status(:no_content)
  end
end
