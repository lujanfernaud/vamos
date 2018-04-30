class Groups::MembershipsController < ApplicationController
  after_action :verify_authorized

  def index
    authorize GroupMembership

    @group = find_group
    @organizers = @group.organizers
    @members = @group.members_with_role

    add_breadcrumbs_for_index
  end

  def create
    @group = find_group
    @user  = User.find(params[:user_id])
    @membership = GroupMembership.create(group: @group, user: @user)

    authorize @membership

    destroy_user_sample_group
    destroy_membership_request
    add_role_to_user

    if current_user == @user
      flash[:success] = "You are now a member of #{@group.name}!"
      redirect_to group_path(@group)
    else
      flash[:success] = "#{@user.name} was accepted " \
                        "as a member of #{@group.name}."
      notify_user_accepted
      redirect_to user_membership_requests_path(current_user)
    end
  end

  def destroy
    @group = find_group
    @user  = User.find(params[:id])
    @membership = GroupMembership.find_by(group: @group, user: @user)

    authorize @membership

    remove_all_user_roles_for_group

    @membership.destroy

    if current_user == @user
      flash[:success] = "Your membership to '#{@group.name}' " \
                        "has been cancelled."
      redirect_to group_path(@group)
    else
      flash[:success] = "#{@user.name} was removed " \
                        "as a member of '#{@group.name}'."
      notify_user_deleted
      redirect_back fallback_location: root_path
    end
  end

  private

    def find_group
      Group.find(params[:group_id])
    end

    def add_breadcrumbs_for_index
      add_breadcrumb @group.name, group_path(@group)
      add_breadcrumb "Organizers & Members"
    end

    def add_role_to_user
      if @group.all_members_can_create_events?
        @user.add_role :organizer, @group
      else
        @user.add_role :member, @group
      end
    end

    def destroy_user_sample_group
      if sample_group = @user.sample_group
        sample_group.destroy
      end
    end

    def destroy_membership_request
      if request_id = params[:request_id]
        MembershipRequest.find(request_id).destroy
      end
    end

    def notify_user_accepted
      NewGroupMembership.call(@membership)
    end

    def notify_user_deleted
      DeletedGroupMembership.call(@membership)
    end

    def remove_all_user_roles_for_group
      user_roles.each do |role|
        @user.remove_role role, @group
      end
    end

    def user_roles
      @user.roles.where(resource: @group).map do |role|
        role.name.to_sym
      end
    end
end