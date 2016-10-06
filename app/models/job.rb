class Job < ApplicationRecord
  include StateDisplay
  include ConfigDisplay

  self.inheritance_column = :_type_disabled

  belongs_to :repository
  belongs_to :commit
  belongs_to :owner, polymorphic: true
  belongs_to :build, foreign_key: 'source_id'

  serialize  :config


  scope :from_repositories, -> (repositories) { where(repository_id: repositories.map(&:id)).includes(:repository) }
  scope :not_finished, -> { where(state: %w[started received queued created]).sort_by {|job|
                                     %w[started received queued created].index(job.state.to_s) } }
  scope :finished, -> { where(state: %w[finished passed failed errored canceled]).order('id DESC') }

  def duration
    (started_at && finished_at) ? (finished_at - started_at) : nil
  end

  def not_finished?
    %w[started received queued created].include? state
  end

  def slug
    @slug ||= repository ? "#{repository.slug}##{number}" : "##{number}"
  end
end
