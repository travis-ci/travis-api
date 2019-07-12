class Organization < ApplicationRecord
  include JobBoost
  include PreferencesHelper

  has_many :memberships
  has_many :abuses, foreign_key: :owner_id, class_name: 'Abuse'
  has_many :users,    through: :memberships
  has_many :repositories,  as: :owner
  has_many :broadcasts,    as: :recipient
  has_one  :subscription,  as: :owner
  has_many :trials,        as: :owner

  def latest_trial
    trials.underway.order(created_at: :desc).first
  end

  def installation
    @installation = ::Installation.where(owner_type: "Organization", owner_id: id).first
  end
end
