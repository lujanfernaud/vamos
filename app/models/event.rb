class Event < ApplicationRecord
  include FriendlyId
  friendly_id :slug_candidates, use: :scoped, scope: :group

  include Storext.model

  store_attributes :updated_fields do
    updated_start_date DateTime
    updated_end_date   DateTime
    updated_address    String
  end

  before_save   :titleize_title
  before_save   :check_website_url
  before_update :store_updated_fields
  after_save    :touch_group

  belongs_to :organizer, class_name: "User"
  belongs_to :group

  has_one :address
  accepts_nested_attributes_for :address, update_only: true

  delegate :place_name, :street1, :street2, :city,
           :state, :post_code, :country,
           :full_address, :full_address_changed?, to: :address, allow_nil: true

  has_many :attendances, foreign_key: "attended_event_id"
  has_many :attendees, through: :attendances

  validates :title,       presence: true, length: { in: 4..140 }
  validates :description, presence: true, length: { in: 32..1000 }
  validates :image,       presence: true
  validate  :no_past_date

  scope :upcoming, -> {
    where("start_date > ?", Time.zone.now).order("start_date ASC")
  }

  scope :three, -> {
    limit(3)
  }

  mount_uploader :image, ImageUploader
  include CarrierWave::SampleImage

  def latitude
    address.latitude if address
  end

  def longitude
    address.longitude if address
  end

  private

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
      start_date.strftime("%b %d %Y")
    end

    def titleize_title
      self.title = title.titleize
    end

    def check_website_url
      return if url_has_protocol? || website.empty?

      self.website = "https://" + website
    end

    def url_has_protocol?
      website =~ /https?\:\/\//
    end

    def store_updated_fields
      clear_previously_updated_fields

      store_updated_start_date
      store_updated_end_date
      store_updated_address
    end

    def clear_previously_updated_fields
      self.updated_fields.clear
    end

    def store_updated_start_date
      self.updated_start_date = start_date if start_date_changed?
    end

    def store_updated_end_date
      self.updated_end_date = end_date if end_date_changed?
    end

    def store_updated_address
      self.updated_address = full_address if full_address_changed?
    end

    def touch_group
      group.touch
    end

    def no_past_date
      if start_date < Time.zone.now
        errors.add(:start_date, "can't be in the past")
      elsif end_date < start_date
        errors.add(:start_date, "can't be later than end date")
      end
    end
end
