class Job < ActiveRecord::Base
  self.inheritance_column = :_type_disabled

  belongs_to :repository
  belongs_to :owner, polymorphic: true

  scope :not_finished, -> { where(state: %w[started received queued created]) }
  scope :from_repositories, -> (repositories) { where(repository_id: repositories.map(&:id)) }
end
