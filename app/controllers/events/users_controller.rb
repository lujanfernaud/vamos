class Events::UsersController < ApplicationController
  before_action :redirect_to_sign_up, if: :not_logged_in?
  after_action  :verify_authorized

  # Group member profile
  def show
    @user  = find_user
    @event = find_event

    authorize @user

    add_breadcrumbs

    render "groups/users/show"
  end

  private

    def redirect_to_sign_up
      redirect_to new_user_registration_path
    end

    def not_logged_in?
      !current_user
    end

    def find_user
      User.find(params[:id])
    end

    def find_event
      Event.find(params[:event_id])
    end

    def add_breadcrumbs
      @group = @event.group

      add_breadcrumb @group.name, group_path(@group)
      add_breadcrumb @event.title, group_event_path(@group, @event)
      add_breadcrumb "Attendees", event_attendances_path(@event)
      add_breadcrumb @user.name
    end
end
