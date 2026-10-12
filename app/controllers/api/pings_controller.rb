class Api::PingsController < ApplicationController
  def show
    render json: { status: "ok", deployed_at: Time.current, version: 1 }
  end
end
