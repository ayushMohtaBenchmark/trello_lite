# Serializes an ActiveStorage::Attachment with a download path.
class AttachmentSerializer
  include Alba::Resource

  attributes :id

  attribute :filename do |att|
    att.blob.filename.to_s
  end

  attribute :content_type do |att|
    att.blob.content_type
  end

  attribute :byte_size do |att|
    att.blob.byte_size
  end

  attribute :url do |att|
    Rails.application.routes.url_helpers.rails_blob_path(att, only_path: true)
  end
end
