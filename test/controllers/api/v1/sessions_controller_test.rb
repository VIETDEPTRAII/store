require "test_helper"

class Api::V1::SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "login_user@example.com", password: "12345678", name: "Viet")
  end

  test "POST /api/v1/login with valid credentials returns user and token" do
    post api_v1_login_path, params: {
      email: "login_user@example.com",
      password: "12345678"
    }, as: :json

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal @user.id, body["user"]["id"]
    assert_equal @user.email, body["user"]["email"]
    assert body["token"].present?

    decoded = JsonWebToken.decode(body["token"])
    assert_equal @user.id, decoded["user_id"]
    assert_equal @user.jti, decoded["jti"]
  end

  test "POST /api/v1/login with wrong password returns 401" do
    post api_v1_login_path, params: {
      email: "login_user@example.com",
      password: "wrong_password"
    }, as: :json

    assert_response :unauthorized
    body = JSON.parse(response.body)
    assert_equal [ "Invalid email or password" ], body["errors"]
  end

  test "POST /api/v1/login with unknown email returns 401" do
    post api_v1_login_path, params: {
      email: "does_not_exist@example.com",
      password: "12345678"
    }, as: :json

    assert_response :unauthorized
    body = JSON.parse(response.body)
    assert_equal [ "Invalid email or password" ], body["errors"]
  end

  test "POST /api/v1/login without password returns 400" do
    post api_v1_login_path, params: { email: "login_user@example.com" }, as: :json

    assert_response :bad_request
    body = JSON.parse(response.body)
    assert_equal [ "Password is required" ], body["errors"]
  end

  test "POST /api/v1/login without email returns 400" do
    post api_v1_login_path, params: { password: "12345678" }, as: :json

    assert_response :bad_request
    body = JSON.parse(response.body)
    assert_equal [ "Email is required" ], body["errors"]
  end
end
