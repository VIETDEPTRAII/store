class Api::EchoesController < ApplicationController
  def show
    system("echo #{params[:message]}")
    render json: { message: params[:message].to_s }
  end
end
