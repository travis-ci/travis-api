class Subscription < ActiveRecord::Base
  belongs_to :owner,   polymorphic: true
  has_many   :plans
  belongs_to :contact, class_name: "User"
  has_many   :invoices

  def active?
    cc_token? && valid_to.present? && valid_to >= Time.now
  end
end
