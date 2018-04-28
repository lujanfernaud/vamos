require 'test_helper'

class EventTest < ActiveSupport::TestCase
  def setup
    stub_requests_to_googleapis
  end

  test "is valid" do
    event = fake_event
    assert event.valid?
  end

  test "is invalid without title" do
    event = fake_event(title: "")
    refute event.valid?
  end

  test "is invalid with short title" do
    event = fake_event(title: "Eve")
    refute event.valid?
  end

  test "is invalid without description" do
    event = fake_event(description: "")
    refute event.valid?
  end

  test "is invalid with short description" do
    event = fake_event(description: "An event")
    refute event.valid?
  end

  test "is invalid without image" do
    event = fake_event(image: "")
    refute event.valid?
  end

  test "is invalid with a start date that has already passed" do
    event = fake_event(start_date: 1.day.ago)
    refute event.valid?
  end

  test "is invalid with an end date that has already passed" do
    event = fake_event(end_date: 1.day.ago)
    refute event.valid?
  end

  test "is invalid without a street" do
    event = fake_event(street1: "")
    refute event.valid?
  end

  test "is invalid without a city" do
    event = fake_event(city: "")
    refute event.valid?
  end

  test "is invalid without a post code" do
    event = fake_event(post_code: "")
    refute event.valid?
  end

  test "is invalid without a country" do
    event = fake_event(country: "")
    refute event.valid?
  end

  test "adds protocol to event's website before saving if missing" do
    event = fake_event(website: "www.eventwebsite.com")
    event.save!

    assert_equal event.website, "https://" + "www.eventwebsite.com"
  end

  test "delegates address methods" do
    event = fake_event

    assert event.place_name
    assert event.street1
    assert event.street2
    assert event.city
    assert event.state
    assert event.post_code
    assert event.country
    assert event.full_address
  end

  test "#group" do
    event = events(:one)
    group = groups(:one)

    assert_equal event.group, group
  end

  test "stores updated fields" do
    event = fake_event
    event.save

    assert event.updated_fields.empty?

    event.start_date = 1.month.from_now
    event.end_date   = 1.month.from_now + 1.hour
    event.save

    assert event.updated_fields.include?("updated_start_date")
    assert event.updated_fields.include?("updated_end_date")
    refute event.updated_fields.include?("updated_address")

    event.address.city = "Santa Cruz de Tenerife"
    event.save

    refute event.updated_fields.include?("updated_start_date")
    refute event.updated_fields.include?("updated_end_date")
    assert event.updated_fields.include?("updated_address")
  end
end
