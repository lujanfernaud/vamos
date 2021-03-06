# frozen_string_literal: true

require 'test_helper'

class EventsShowTest < ActionDispatch::IntegrationTest
  def setup
    stub_sample_content_for_new_users
  end

  test "logged in user visits event" do
    penny = users(:penny)
    group = groups(:one)
    event = events(:one)
    decorated_event = EventDecorator.new(event)

    attendees = build_list :user, 10
    event.attendees << attendees
    event.reload

    log_in_as(penny)
    visit group_event_path(group, event)

    assert_event_information(decorated_event)
    assert_comments
    assert_attendees_preview(event)
    assert_quick_access

    refute page.has_link?    "Edit event"
    assert page.has_content? "Would you like to attend?"
    assert page.has_link?    "Attend"

    assert_attendees(event)
  end

  test "logged in user visits event without website" do
    user  = create :user, :confirmed
    group = create :group
    group.members << user

    event = create :event, group: group, website: ""
    event.attendees << user

    log_in_as(user)
    visit group_event_path(group, event)

    within ".quick-access" do
      assert_not page.has_link? "Visit event website"
    end
  end

  test "logged out user visits event" do
    group = groups(:one)
    event = EventDecorator.new(events(:one))

    visit group_event_path(group, event)

    assert_current_path new_user_session_path
  end

  test "logged out invited user visits event" do
    event = create :event
    group = event.group

    invitation = create :group_invitation,
                         group:  group,
                         sender: group.owner,
                         email:  "test@test.test"

    visit group_path(group, token: invitation.token)
    visit group_event_path(group, event)

    assert_current_path group_event_path(group, event)
  end

  test "logged in invited user visits event" do
    user  = create :user
    event = create :event
    group = event.group

    invitation = create :group_invitation,
                         group:  group,
                         sender: group.owner,
                         email:  user.email

    log_in_as user

    visit group_path(group, token: invitation.token)
    visit group_event_path(group, event)

    assert_current_path group_event_path(group, event)
  end

  test "event organizer visits event" do
    phil  = users(:phil)
    group = groups(:one)
    event = events(:one)

    log_in_as(phil)
    visit group_event_path(group, event)

    assert page.has_link?    "Edit event"
    refute page.has_content? "Would you like to attend?"
    refute page.has_link?    "Attend"
  end

  test "event organizer visits event without attendees" do
    event = create :event
    group = event.group
    group.members << event.organizer

    log_in_as(event.organizer)
    visit group_event_path(event.group, event)

    assert page.has_content? "So far there are no attendees. " \
                             "We need to promote this!"
  end

  test "user visits event without attendees" do
    user  = create :user
    event = create :event
    group = event.group
    group.members << user

    log_in_as(user)
    visit group_event_path(event.group, event)

    assert page.has_content? "So far there are no attendees. " \
                             "You can be the first one!"
  end

  test "user attends and cancels attendance" do
    prepare_javascript_driver

    group = groups(:one)
    event = events(:one)
    penny = users(:penny)
    penny.add_role :member, group

    log_in_as(penny)
    visit group_event_path(group, event)

    click_on "Attend"

    assert page.has_content? "You are attending this event!"
    assert page.has_content? "Cancel attendance"

    click_on "Cancel attendance"

    assert page.has_link? "Attend"
  end

  test "website url is not shown if the event has no website" do
    group = groups(:one)
    event = events(:two)

    visit group_event_path(group, event)

    refute page.has_link? "https://"
  end

  private

    def assert_event_information(event)
      event_information_attributes(event).each do |attribute_data|
        assert page.has_content? attribute_data
      end
    end

    def event_information_attributes(event)
      [
        event.title,
        event.start_date_prettyfied,
        event.full_address,
        event.description
      ]
    end

    def assert_comments
      assert page.has_css? ".comments-container"
      assert page.has_css? "form#new_topic_comment"
    end

    def assert_attendees_preview(event)
      within ".attendees-preview" do
        assert page.has_content? "Attendees (#{event.attendees_count})"
        assert page.has_content? "See all attendees"
      end
    end

    def assert_quick_access
      within ".quick-access" do
        assert page.has_link? "See location in map"
        assert page.has_link? "Visit event website"
      end
    end

    def assert_attendees(event)
      within ".attendees-container" do
        assert page.has_content? "Attendees (#{event.attendees_count})"
        assert page.has_css?     ".user-box"
      end
    end
end
