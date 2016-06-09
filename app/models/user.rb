class User < ActiveRecord::Base
  has_many :emails
  has_many :memberships
  has_many :organizations, through: :memberships
  has_many :repositories,  as:      :owner
end
