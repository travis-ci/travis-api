class Job < ActiveRecord::Base
  self.inheritance_column = :_type_disabled

  belongs_to :repository
  belongs_to :commit
  belongs_to :owner, polymorphic: true
  belongs_to :build, foreign_key: 'source_id'


  scope :from_repositories, -> (repositories) { where(repository_id: repositories.map(&:id)) }
  scope :not_finished, -> { where(state: %w[started received queued created]).sort_by {|job|
                                     %w[started received queued created].index(job.state.to_s) } }
  scope :finished, -> { where(state: %w[passed failed errored canceled]).order('id DESC') }

  def duration
    started_at && finished_at ? finished_at - started_at : nil
  end

  def time
    case state
    when 'canceled'
      canceled_at
    when 'errored', 'passed', 'failed', 'finished'
      finished_at
    when 'started'
      started_at
    when 'queued'
      queued_at
    when 'created'
      created_at
    end
  end
end
