class Api::PingsController < ApplicationController
  def show
    # Test RuboCop lint scanner (CI/CD)
    # render json: {status: "ok"}
    render json: { status: "ok" }
  end
end
