# frozen_string_literal: true

class Topic < ApplicationRecord
  MINIMUM_BODY_LENGTH = 20

  include FriendlyId
  friendly_id :slug_candidates, use: :scoped, scope: :group

  belongs_to :group
  belongs_to :user

  has_many :topic_comments, dependent: :destroy

  validates :title, presence: true, length: { minimum: 2 }
  validate  :body_length

  scope :prioritized, -> {
    order(priority: :desc, updated_at: :desc).includes(:user)
  }

  scope :normal, -> {
    where(type: nil)
  }

  scope :events, -> {
    where(type: "EventTopic")
  }

  def comments
    topic_comments.order(:created_at).includes(:user)
  end

  def type_presentable
    return unless type

    type.gsub("Topic", "")
  end

  private

    def body_length
      BodyLengthValidator.call(self, length: MINIMUM_BODY_LENGTH)
    end

    def should_generate_new_friendly_id?
      title_changed?
    end

    def slug_candidates
      [
        :title,
        [:title, :date]
      ]
    end

    def date
      Time.zone.now.strftime("%b %d %Y")
    end
end
