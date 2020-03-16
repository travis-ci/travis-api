class Payload < ApplicationRecord
  self.table_name = :request_payloads
  belongs_to :request
  serialize  :payload
end

class Request < ApplicationRecord
  belongs_to :owner, polymorphic: true
  belongs_to :commit
  belongs_to :repository
  has_many   :builds
  has_one    :payload


  scope :from_owner, -> (owner_type, owner_id) { where(owner_type: owner_type, owner_id: owner_id) }
  scope :from_repositories, -> (repositories) { where(repository_id: repositories.map(&:id)).includes(:repository) }

  def payload
    super&.payload
  end

end
