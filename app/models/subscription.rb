class Subscription < ApplicationRecord
  belongs_to :owner,   polymorphic: true
  belongs_to :contact, class_name: "User"
  has_many   :invoices

	EU = [
		'Austria', 'Belgium', 'Bulgaria', 'Cyprus', 'Czech Republic',
		'Denmark', 'Estonia', 'Finland', 'France', 'Monaco', 'Greece',
		'Hungary', 'Ireland', 'Italy', 'Latvia', 'Lithuania', 'Luxembourg',
		'Malta', 'Netherlands', 'Poland', 'Portugal', 'Romania', 'Slovakia',
		'Slovenia', 'Spain', 'Sweden', 'United Kingdom', 'Isle of Man', 'Croatia'
	].freeze

  validates :valid_to, date: true, allow_blank: true
	# TODO: we're skipping this validation unless we changed the value because we have old invalid
	# values in the database which make saving unrelated updates fail. Same as above, we should fix
	# those in the database if possible! And then remove the condition.
	validates :vat_id, valvat: { lookup: :fail_if_down }, allow_blank: true, if: :vat_id_changed?

	def vat_required?
		(country == 'Germany') || (EU.include?(country) && !vat_id?)
	end

  biggs :postal_address,
        recipient:  :recipient,
        zip:        :zip_code,
        city:       :city,
        street:     [:address, :address2],
        state:      :state,
        country:    :iso_code

  def active?
    cc_token? && valid_to.present? && valid_to >= Time.now
  end

  def expired?
    valid_to && valid_to < Time.now
  end

  def github?
    source == "github"
  end

  def valid_to
    super.to_date unless super.nil?
  end

  def valid_to=(date)
    super(date.to_date)
  end

  private
    def name
      if first_name || last_name
        [first_name.presence, last_name.presence].compact.join(" ")
      elsif contact && contact.name.present?
        contact.name
      elsif owner.is_a?(User) && owner.name.present?
        owner.name
      end
    end

    def recipient
      if company.present?
        name ? "#{name}, #{company}" : company
      else
        name || owner.login
      end
    end

    def iso_code
      Biggs.country_names.key(country)
    end
end
