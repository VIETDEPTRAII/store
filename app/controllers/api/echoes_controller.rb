class Api::EchoesController < ApplicationController
  def show
    # Test brakeman security scanner (CI/CD)
    # system("echo #{params[:message]}")
    render json: { message: params[:message].to_s }
  end
end
