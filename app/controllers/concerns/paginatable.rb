# Offset pagination via Pagy. Page metadata is returned in response headers
# (X-Total-Count, X-Page, X-Per-Page, X-Total-Pages) plus a RFC-5988 Link header.
module Paginatable
  extend ActiveSupport::Concern
  include Pagy::Backend

  MAX_PER_PAGE = 100
  DEFAULT_PER_PAGE = 25

  included do
    rescue_from Pagy::OverflowError do
      render_error(code: "page_out_of_range", message: "Requested page is out of range",
                   status: :unprocessable_entity)
    end
  end

  def paginate(scope)
    pagy, records = pagy(scope, limit: per_page)
    set_pagination_headers(pagy)
    records
  end

  private

  def per_page
    requested = params.fetch(:per_page, DEFAULT_PER_PAGE).to_i
    requested.clamp(1, MAX_PER_PAGE)
  end

  def set_pagination_headers(pagy)
    response.set_header("X-Total-Count", pagy.count.to_s)
    response.set_header("X-Page", pagy.page.to_s)
    response.set_header("X-Per-Page", pagy.limit.to_s)
    response.set_header("X-Total-Pages", pagy.pages.to_s)
    response.set_header("Link", link_header(pagy)) if pagy.pages > 1
  end

  def link_header(pagy)
    base = request.base_url + request.path
    links = []
    add = ->(page, rel) { links << %(<#{base}?#{request.query_parameters.merge(page: page).to_query}>; rel="#{rel}") }
    add.call(pagy.next, "next") if pagy.next
    add.call(pagy.prev, "prev") if pagy.prev
    add.call(1, "first")
    add.call(pagy.pages, "last")
    links.join(", ")
  end
end
