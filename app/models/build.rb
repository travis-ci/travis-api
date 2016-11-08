class Build < ApplicationRecord
  include StateDisplay
  include ConfigDisplay

  belongs_to :owner,    polymorphic: true
  belongs_to :repository
  belongs_to :commit
  belongs_to :request
  has_many   :jobs,     as: :source

  serialize :config

  scope :not_finished,    -> { where(state: %w[started received queued created]).sort_by {|build|
    %w[started received queued created].index(build.state.to_s) } }
  scope :finished,        -> { where(state: %w[finished passed failed errored canceled]).order('id DESC') }
  scope :from_repository, -> (repository) { where(repository_id: repository.id) }

  def not_finished?
    %w[started received queued created].include? state
  end
end
