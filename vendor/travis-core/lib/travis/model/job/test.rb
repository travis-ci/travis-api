require 'active_support/core_ext/hash/slice'
require 'simple_states'

class Job

  # Executes a test job (i.e. runs a test suite) remotely and keeps tabs about
  # state changes throughout its lifecycle in the database.
  #
  # Job::Test belongs to a Build as part of the build matrix and will be
  # created with the Build.
  class Test < Job
    FINISHED_STATES = [:passed, :failed, :errored, :canceled]
    FAILED_STATES = [:failed, :errored, :canceled]

    include SimpleStates, Travis::Event

    states :created, :queued, :received, :started, :passed, :failed, :errored, :canceled

    event :receive, to: :received
    event :start,   to: :started
    event :finish,  to: :finished
    event :reset,   to: :created, unless: :created?
    event :cancel,  to: :canceled, if: :cancelable?
    event :all, after: [:propagate, :notify]

    def enqueue # TODO rename to queue and make it an event, simple_states should support that now
      update_attributes!(state: :queued, queued_at: Time.now.utc)
      notify(:queue)
    end

    def receive(data = {})
      log.update_attributes!(content: '', removed_at: nil, removed_by: nil) # TODO this should be in a restart method, right?
      data = data.symbolize_keys.slice(:received_at, :worker)
      data.each { |key, value| send(:"#{key}=", value) }
    end

    def start(data = {})
      data = data.symbolize_keys.slice(:started_at)
      data.each { |key, value| send(:"#{key}=", value) }
    end

    def finish(data = {})
      data = data.symbolize_keys.slice(:state, :finished_at)
      data.each { |key, value| send(:"#{key}=", value) }
    end

    def reset(*)
      self.state = :created
      attrs = %w(started_at queued_at finished_at worker)
      attrs.each { |attr| write_attribute(attr, nil) }
      if log
        log.clear!
      else
        build_log
      end
      annotations.destroy_all
    end

    def cancel
      self.canceled_at = Time.now
      self.finished_at = Time.now

      save!
    end

    def cancelable?
      !finished?
    end

    def resetable?
      finished? && !invalid_config?
    end

    def invalid_config?
      config[:".result"] == "parse_error"
    end

    def finished?
      FINISHED_STATES.include?(state.to_sym)
    end

    def finished_unsuccessfully?
      FAILED_STATES.include?(state.to_sym)
    end

    def passed?
      state.to_s == "passed"
    end

    def failed?
      state.to_s == "failed"
    end

    def unknown?
      state == nil
    end

    def notify(event, *args)
      Metriks.timer("job.notify.#{event}").time do
        event = :create if event == :reset
        super
      end
    end

    delegate :id, :content, :to => :log, :prefix => true, :allow_nil => true
  end
end
