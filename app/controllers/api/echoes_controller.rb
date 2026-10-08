class Api::EchoesController < ApplicationController
  def show
    return render json: { message: params[:message].to_s }
  end
end
