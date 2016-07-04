class User < ActiveRecord::Base
  has_many :emails
  has_many :memberships
  has_many :permissions
  has_many :organizations,          through: :memberships
  has_many :repositories,           as:      :owner
  has_many :permitted_repositories, through: :permissions, source: :repository
  has_many :broadcasts,             as:      :recipient
  has_one  :subscription,           as:      :owner
end
