class NotificationMailer < ApplicationMailer
  default from: "notifications@letsmeet.com"

  def new_membership_request(user, group)
    @user  = user
    @group = group
    @owner = @group.owner
    @url   = user_notifications_url(@owner)

    mail(
      to: @owner.email,
      subject: "New membership request from #{@user.name} in #{@group.name}"
    )
  end

  def declined_membership_request(user, group)
    default_notification_email(
      user, group, subject: "Membership request declined"
    )
  end

  def new_group_membership(user, group)
    default_notification_email(
      user, group, subject: "#{group.name} membership"
    )
  end

  def deleted_group_membership(user, group)
    default_notification_email(
      user, group, subject: "Your #{group.name} membership was cancelled"
    )
  end

  private

    def default_notification_email(user, group, subject:)
      @user  = user
      @group = group
      @url   = user_notifications_url(@user)

      mail(
        to: @user.email,
        subject: subject
      )
    end
end
