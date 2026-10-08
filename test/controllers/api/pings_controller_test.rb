require "test_helper"

class Api::PingsControllerTest < ActionDispatch::IntegrationTest
  test "GET /api/ping returns ok status as JSON" do
    get api_ping_path

    assert_response :success
    assert_equal "application/json; charset=utf-8", response.content_type
    assert_equal({ "status" => "ok" }, JSON.parse(response.body))
  end
end
