# frozen_string_literal: true

require 'test_helper'

class CommentsUpdateTest < ActionDispatch::IntegrationTest
  include TopicsIntegrationSupport
  include CommentsIntegrationSupport

  def setup
    @group   = groups(:one)
    @phil    = users(:phil)
    @topic   = topics(:one)
    @comment = topic_comments(:one)

    prepare_javascript_driver
  end

  test "author updates comment" do
    log_in_as @phil

    visit group_topic_path(@group, @topic)

    click_on_edit_comment(@comment)

    update_comment_with "Revised comment."

    assert page.has_content? "Comment updated."
    assert_equal group_topic_path(@group, @topic), current_path

    within "#comment-#{@comment.id}" do
      refute page.has_content? "Edited"
    end
  end

  test "topic does not show 'edited' after editing comment" do
    @topic.update_attributes   edited_at:  1.hour.ago
    @comment.update_attributes created_at: 1.hour.ago

    log_in_as @phil

    visit group_topic_path(@group, @topic)

    click_on_edit_comment(@comment)

    update_comment_with("Body of updated comment.")

    within "#comment-#{@comment.id}" do
      assert page.has_content? "Edited"
    end

    within "#topic-#{@topic.id}" do
      assert_not page.has_content? "Edited"
    end
  end

  test "shows 'edited' if edited after offset" do
    @comment.update_attributes(
      created_at: 1.hour.ago,
      updated_at: 6.minutes.ago
    )

    log_in_as @phil

    visit group_topic_path(@group, @topic)

    within "#comment-#{@comment.id}" do
      assert page.has_content? "Edited"
    end
  end

  test "shows 'edited by' if edited by a different user" do
    woodell = users(:woodell)

    @comment.update_attributes(
      created_at: 1.hour.ago,
      updated_at: 6.minutes.ago,
      edited_by:  woodell
    )

    log_in_as @phil

    visit group_topic_path(@group, @topic)

    within "#comment-#{@comment.id}" do
      assert page.has_content? "Edited by Woodell"
    end
  end

  test "moderator can update comment" do
    user = users(:woodell)
    @group.add_to_moderators user

    log_in_as user

    visit group_topic_path(@group, @topic)

    click_on_edit_comment(@comment)

    update_comment_with "Revised comment."

    assert page.has_content? "Comment updated."
  end

  test "regular user can't update comment" do
    user = users(:carolyn)
    @group.members << user
    @group.remove_from_organizers user

    log_in_as user

    visit group_topic_path(@group, @topic)

    within "#comment-#{@comment.id}" do
      refute page.has_link? "Edit"
    end
  end
end
