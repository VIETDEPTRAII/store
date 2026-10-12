require "test_helper"

class Api::EchoesControllerTest < ActionDispatch::IntegrationTest
  test "GET /api/echo returns the message param as JSON" do
    get api_echo_path(message: "hello")

    assert_response :success
    assert_equal "application/json; charset=utf-8", response.content_type
    assert_equal({ "message" => "hello" }, JSON.parse(response.body))
  end

  test "GET /api/echo without a message param returns an empty message" do
    get api_echo_path

    assert_response :success
    assert_equal({ "message" => "" }, JSON.parse(response.body))
  end
end
