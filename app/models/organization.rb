class Organization < ActiveRecord::Base
  include JobBoost

  has_many :memberships
  has_many :users,    through: :memberships
  has_many :repositories,  as: :owner
  has_many :broadcasts,    as: :recipient
  has_one  :subscription,  as: :owner
end
