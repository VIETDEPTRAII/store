class Api::V1::BaseController < ApplicationController
  wrap_parameters false
  skip_before_action :verify_authenticity_token, raise: false
end
