class Api::V1::SessionsController < Api::V1::BaseController
  def create
    @user = User.find_by(email: login_params[:email]&.downcase)

    if @user&.authenticate(login_params[:password])
      @token = JsonWebToken.encode(user_id: @user.id, jti: @user.jti)
      render :create, status: :ok
    else
      render json: { errors: [ "Invalid email or password" ] }, status: :unauthorized
    end
  end

  private

  def login_params
    params.require(:email)
    params.require(:password)
    params.permit(:email, :password)
  end
end
