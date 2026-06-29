# Consistent JSON error envelope: { "error": { "code", "message", "details" } }.
module ErrorHandling
  extend ActiveSupport::Concern

  included do
    rescue_from ActiveRecord::RecordNotFound,        with: :render_not_found
    rescue_from ActiveRecord::RecordInvalid,         with: :render_record_invalid
    rescue_from ActionController::ParameterMissing,  with: :render_parameter_missing
    rescue_from Pundit::NotAuthorizedError,          with: :render_forbidden
  end

  def render_error(code:, message:, status:, details: nil)
    body = { error: { code: code, message: message } }
    body[:error][:details] = details if details.present?
    render json: body, status: status
  end

  private

  def render_not_found(error)
    render_error(code: "not_found", message: "#{error.model || 'Record'} not found",
                 status: :not_found)
  end

  def render_record_invalid(error)
    render_error(code: "validation_failed", message: "Validation failed",
                 status: :unprocessable_entity,
                 details: error.record.errors.to_hash(true))
  end

  def render_parameter_missing(error)
    render_error(code: "parameter_missing", message: error.message,
                 status: :bad_request)
  end

  def render_forbidden(_error)
    render_error(code: "forbidden", message: "You are not allowed to perform this action",
                 status: :forbidden)
  end
end
