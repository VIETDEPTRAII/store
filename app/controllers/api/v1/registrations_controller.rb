class Api::V1::RegistrationsController < Api::V1::BaseController
  def create
    @user = User.new(user_params)

    if @user.save
      render json: { user: { id: @user.id, email: @user.email, name: @user.name } }, status: :created
    else
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:email)
    params.require(:password)
    params.permit(:email, :password, :name)
  end
end
