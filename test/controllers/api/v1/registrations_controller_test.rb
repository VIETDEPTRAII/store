require "test_helper"

class Api::V1::RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "POST /api/v1/registration with valid params creates a user" do
    post api_v1_registration_path, params: {
      email: "new_user@example.com",
      password: "12345678",
      name: "Viet"
    }, as: :json

    assert_response :created
    body = JSON.parse(response.body)
    assert_equal "new_user@example.com", body["user"]["email"]
    assert_equal "Viet", body["user"]["name"]
    assert body["user"]["id"].present?
    assert_not body.key?("password_digest")
  end

  test "POST /api/v1/registration with duplicate email returns 422" do
    User.create!(email: "taken@example.com", password: "12345678")

    post api_v1_registration_path, params: {
      email: "taken@example.com",
      password: "12345678"
    }, as: :json

    assert_response :unprocessable_entity
    body = JSON.parse(response.body)
    assert_includes body["errors"].join, "Email has already been taken"
  end

  test "POST /api/v1/registration with short password returns 422" do
    post api_v1_registration_path, params: {
      email: "short_password@example.com",
      password: "123"
    }, as: :json

    assert_response :unprocessable_entity
    body = JSON.parse(response.body)
    assert body["errors"].present?
  end

  test "POST /api/v1/registration without password returns 400" do
    post api_v1_registration_path, params: { email: "missing_password@example.com" }, as: :json

    assert_response :bad_request
    body = JSON.parse(response.body)
    assert_equal [ "Password is required" ], body["errors"]
  end

  test "POST /api/v1/registration without email returns 400" do
    post api_v1_registration_path, params: { password: "12345678" }, as: :json

    assert_response :bad_request
    body = JSON.parse(response.body)
    assert_equal [ "Email is required" ], body["errors"]
  end
end
