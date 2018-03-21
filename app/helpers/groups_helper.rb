module GroupsHelper
  include SessionsHelper
  include GroupCountersHelper

  def has_organizer_role?(user, group)
    user&.has_role? :organizer, group
  end

  def has_member_role?(user, group)
    group.owner == user || user&.has_role?(:member, group)
  end

  def has_membership?(user, group)
    group.owner == user || group.members.include?(user)
  end

  def see_all_members_link(group, quantity:)
    if group.members.count > quantity
      link_to "See all members", group_members_path(group)
    end
  end

  def membership_button(group)
    if group.private? && logged_in?
      if current_user.sent_requests.include?(group)
        button_tag "Membership requested", disabled: true,
          class: "btn btn-primary btn-block btn-lg mt-3"
      else
        link_to "Request membership", new_group_membership_request_path(group),
          class: "btn btn-primary btn-block btn-lg mt-3"
      end
    elsif group.private?
      link_to "Log in to request membership", "#",
        class: "btn btn-primary btn-block btn-lg mt-3"
    elsif !group.private? && logged_in?
      link_to "Join group", group_members_path(group, user_id: current_user),
        method: :post, class: "btn btn-primary btn-block btn-lg mt-3"
    else
      link_to "Log in to join group", "#",
        class: "btn btn-primary btn-block btn-lg mt-3"
    end
  end
end