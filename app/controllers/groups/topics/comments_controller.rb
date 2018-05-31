# frozen_string_literal: true

class Groups::Topics::CommentsController < ApplicationController
  after_action :verify_authorized

  def edit
    @comment = find_comment
    @topic   = @comment.topic
    @group   = @topic.group

    authorize @comment

    add_breadcrumbs_for_comment_edition
  end

  def create
    @group   = find_group
    @topic   = find_topic
    @comment = create_comment

    authorize @comment

    add_breadcrumbs_for_comment_creation

    if @comment.save
      flash[:success] = "New comment created."
      redirect_to group_topic_path(@group, @topic)
    else
      render "groups/topics/show"
    end
  end

  def update
    @comment = find_comment
    @topic   = @comment.topic
    @group   = @topic.group

    authorize @comment

    add_breadcrumbs_for_comment_edition

    if @comment.update_attributes(comment_params)
      flash[:success] = "Comment updated."
      redirect_to group_topic_path(@group, @topic)
    else
      render :edit
    end
  end

  def destroy
    @comment = find_comment
    @topic   = @comment.topic
    @group   = @topic.group

    authorize @comment

    @comment.destroy

    flash[:success] = "Comment deleted."
    redirect_to group_topic_path(@group, @topic)
  end

  private

    def find_comment
      TopicComment.find(params[:id])
    end

    def find_group
      Group.find(params[:group_id])
    end

    def find_topic
      Topic.find(params[:topic_id])
    end

    def create_comment
      TopicComment.new(
        comment_params.merge(topic: @topic, user: current_user)
      )
    end

    def add_breadcrumbs_for_comment_edition
      add_base_breadcrumbs
      add_breadcrumb "Edit comment"
    end

    def add_breadcrumbs_for_comment_creation
      add_base_breadcrumbs
      add_breadcrumb "New comment"
    end

    def add_base_breadcrumbs
      add_breadcrumb @group.name, group_path(@group)
      add_breadcrumb "Topics", group_topics_path(@group)
      add_breadcrumb @topic.title, group_topic_path(@group, @topic)
    end

    def comment_params
      params.require(:topic_comment).permit(:body)
    end
end
