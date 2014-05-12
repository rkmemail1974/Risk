require 'test_helper'

class GamesControllerTest < ActionController::TestCase
  test "should get join" do
    get :join
    assert_response :success
  end

  test "should get play" do
    get :play
    assert_response :success
  end

end
