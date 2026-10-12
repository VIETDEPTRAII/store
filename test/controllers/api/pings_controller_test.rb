require "test_helper"

class Api::PingsControllerTest < ActionDispatch::IntegrationTest
  test "GET /api/ping returns ok status as JSON" do
    get api_ping_path

    assert_response :success
    assert_equal "application/json; charset=utf-8", response.content_type
    body = JSON.parse(response.body)
    assert_equal "ok", body["status"]
    assert body["deployed_at"].present?
  end
end
