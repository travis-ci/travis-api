class Job < ActiveRecord::Base
  self.inheritance_column = :_type_disabled

  belongs_to :repository
  belongs_to :owner, polymorphic: true

  scope :from_repositories, -> (repositories) { where(repository_id: repositories.map(&:id)) }
  scope :not_finished, -> { where(state: %w[started received queued created]).sort_by {|job|
                                     %w[started received queued created].index(job.state.to_s) } }
end
