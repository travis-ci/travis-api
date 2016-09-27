class Organization < ApplicationRecord
  include JobBoost
  include Searchable

  has_many :memberships
  has_many :users,    through: :memberships
  has_many :repositories,  as: :owner
  has_many :broadcasts,    as: :recipient
  has_one  :subscription,  as: :owner

  def as_indexed_json(options = nil)
    self.as_json(only: [:name, :login])
  end
end
