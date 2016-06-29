module StateMessages
  extend ActiveSupport::Concern

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
