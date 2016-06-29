class Build < ActiveRecord::Base
  belongs_to :owner, polymorphic: true
  belongs_to :repository
  belongs_to :commit
  belongs_to :request
  has_many   :jobs,     as: :source

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
