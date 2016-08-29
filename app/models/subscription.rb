class Subscription < ActiveRecord::Base
  belongs_to :owner,   polymorphic: true
  has_many   :plans
  belongs_to :contact, class_name: "User"
  has_many   :invoices

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
