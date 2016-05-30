require 'active_support/concern'
require 'simple_states'

class Build

  # A Build goes through the following lifecycle:
  #
  #  * A newly created Build is in the `created` state.
  #  * When started it sets its `started_at` attribute from the given
  #    (worker) payload.
  #  * A build won't be restarted if it already is started (each matrix job
  #    will try to start it).
  #  * A build will be finished only if all matrix jobs are finished (each
  #    matrix job will try to finish it).
  #  * After both `start` and `finish` events the build will denormalize
  #    attributes to its repository and notify event listeners.
  module States
    extend ActiveSupport::Concern
    include Denormalize, Travis::Event

    included do
      include SimpleStates

      states :created, :received, :started, :passed, :failed, :errored, :canceled

      event :receive, to: :received,  unless: [:received?, :started?, :failed?, :errored?]
      event :start,   to: :started,   unless: [:started?, :failed?, :errored?]
      event :finish,  to: :finished, if: :should_finish?
      event :reset,   to: :created
      event :cancel,  to: :canceled, if: :cancelable?
      event :all, after: [:denormalize, :notify]
    end

    def should_finish?
      matrix_finished? && !finished?
    end

    def receive(data = {})
      self.received_at = data[:received_at]
    end

    def start(data = {})
      self.started_at = data[:started_at]
    end

    def finish(data = {})
      self.state = matrix_state
      self.duration = matrix_duration
      self.finished_at = data[:finished_at]

      save!
    end

    def cancel(options = {})
      matrix.each do |job|
        job.cancel!
      end

      finalize_cancel
    end

    def finalize_cancel
      self.state       = matrix_state
      self.duration    = matrix_duration
      self.canceled_at = Time.now
      self.finished_at = Time.now

      save!
    end

    def cancel_job
      if matrix_finished?
        finalize_cancel
        denormalize(:cancel)
      end
    end

    def reset(options = {})
      self.state = :created unless matrix.any? { |job| job.state == :started }
      %w(duration started_at finished_at).each { |attr| write_attribute(attr, nil) }
      matrix.each(&:reset!) if options[:reset_matrix]
    end

    def resetable?
      finished? && !invalid_config?
    end

    def invalid_config?
      config[:".result"] == "parse_error"
    end

    def pending?
      created? || started?
    end

    def finished?
      passed? || failed? || errored? || canceled?
    end

    def color
      pending? ? 'yellow' : passed? ? 'green' : 'red'
    end

    def notify(event, *args)
      event = :create if event == :reset
      super
    end
  end
end
