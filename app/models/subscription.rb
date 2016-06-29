class Subscription < ActiveRecord::Base
  belongs_to :owner,   polymorphic: true
  has_many   :plans
  belongs_to :contact, class_name: "User"
  has_many   :invoices

  def active?
    cc_token? and valid_to.present? and valid_to >= Time.now.utc
  end
end
