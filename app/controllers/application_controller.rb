class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  rescue_from ActionController::ParameterMissing do |e|
    render json: { errors: [ "#{e.param.to_s.humanize} is required" ] }, status: :bad_request
  end
end
