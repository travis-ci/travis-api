class Request < ApplicationRecord
  belongs_to :owner, polymorphic: true
  belongs_to :commit
  belongs_to :repository
  has_many   :builds

  serialize  :payload

  scope :from_owner, -> (owner_type, owner_id) { where(owner_type: owner_type, owner_id: owner_id).order('id DESC').take(30) }
end
