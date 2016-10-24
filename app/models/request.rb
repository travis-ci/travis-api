class Request < ApplicationRecord
  belongs_to :owner, polymorphic: true
  belongs_to :commit
  belongs_to :repository
  has_many   :builds

  serialize  :payload

  scope :from_owner, -> (owner_type, owner_id) { where(owner_type: owner_type, owner_id: owner_id) }
  scope :from_repositories, -> (repositories) { where(repository_id: repositories.map(&:id)).includes(:repository) }
end
