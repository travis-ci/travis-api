class Organization < ApplicationRecord
  include JobBoost
  include PreferencesHelper

  has_many :memberships
  has_many :abuses, foreign_key: :owner_id, class_name: 'Abuse'
  has_many :users,    through: :memberships
  has_many :repositories,  as: :owner
  has_many :broadcasts,    as: :recipient
  has_many :trials,        as: :owner

  def latest_trial
    trials.underway.order(created_at: :desc).first
  end

  def installation
    @installation = Installation.where(owner_type: "Organization", owner_id: id).first
  end

  def subscription
    v2_service = Services::Billing::V2Subscription.new(id.to_s, 'Organization')
    v2_subscription = v2_service.subscription
    v2_subscription || Subscription.find_by(owner_id: id)
  end
end
