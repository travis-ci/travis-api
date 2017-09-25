class Organization < ApplicationRecord
  include JobBoost

  has_many :memberships
  has_many :users,    through: :memberships
  has_many :repositories,  as: :owner
  has_many :broadcasts,    as: :recipient
  has_one  :subscription,  as: :owner
  has_many :trials,        as: :owner

  def latest_trial
    trials.underway.order(created_at: :desc).first
  end
end
