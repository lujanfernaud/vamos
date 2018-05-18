require 'test_helper'

class UsersProfileTest < ActionDispatch::IntegrationTest
  def setup
    @phil     = users(:phil)
    @penny    = users(:penny)
    @onitsuka = users(:onitsuka)
  end

  test "user visits someone's profile" do
    log_in_as(@penny)

    visit user_path(@phil)

    assert page.has_content? @phil.name
    assert page.has_css?     ".user-avatar"

    assert page.has_content? "Location"
    assert page.has_content? @phil.location

    assert page.has_content? "Bio"
    assert page.has_content? @phil.bio
  end

  test "profile shows edit link for logged in user" do
    log_in_as(@phil)

    visit user_path(@phil)

    assert page.has_content? "Edit profile"
  end

  test "profile does not show edit link for other users" do
    log_in_as(@phil)

    visit user_path(@penny)

    assert_not page.has_content? "Edit profile"
  end

  test "active tab in profile settings is 'Profile' tab" do
    log_in_as(@phil)

    visit edit_user_path(@phil)

    within ".nav-item-profile" do
      assert page.has_css? ".nav-link.active"
    end
  end

  test "update profile with valid name" do
    log_in_as(@phil)

    visit edit_user_path(@phil)

    fill_in  "Name", with: "Philip"
    click_on "Update"

    assert_valid_for(@phil)
  end

  test "update profile with invalid name" do
    log_in_as(@phil)

    visit edit_user_path(@phil)

    fill_in  "Name", with: "Ph"
    click_on "Update"

    assert_invalid_for(@phil) do
      assert page.has_content? "Name is too short"
    end
  end

  private

    def assert_valid_for(user)
      friendly_user = User.find(user.id)

      assert current_path == user_path(friendly_user)
      assert page.has_content? "updated"
    end

    def assert_invalid_for(user)
      friendly_user = User.find(user.id)

      assert current_path == user_path(friendly_user)
      assert page.has_content? "error"
      yield if block_given?
    end
end
