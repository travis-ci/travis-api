class Subscription < ActiveRecord::Base
  self.table_name = 'subscriptions'
  EU = [
    "Austria", "Belgium", "Bulgaria", "Cyprus", "Czech Republic",
    "Denmark", "Estonia", "Finland", "France", "Monaco", "Greece",
    "Hungary", "Ireland", "Italy", "Latvia", "Lithuania", "Luxembourg",
    "Malta", "Netherlands", "Poland", "Portugal", "Romania", "Slovakia",
    "Slovenia", "Spain", "Sweden", "United Kingdom", "Isle of Man", "Croatia"
  ]

  belongs_to :owner, polymorphic: true
  belongs_to :contact, class_name: "User"
  has_many :invoices

  def active?
    cc_token? and valid_to.present? and valid_to >= Time.now.utc
  end

  def vat_required?
    germany? or (eu? and not vat_id?)
  end

  def eu?
    EU.include?(country)
  end

  def germany?
    country == "Germany"
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  def data_complete?
    billing_email? and cc_token? and selected_plan.present? and country.present?
  end

  def billing_address?
    country? and zip_code? and address? and billing_email? and name?
  end

  def name?
    company? or (first_name? and last_name?)
  end
end
