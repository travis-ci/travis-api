require 'active_support/concern'
require 'active_support/core_ext/hash/keys'
require 'core_ext/hash/deep_symbolize_keys'

class Build

  # A Build contains a number of Job::Test instances that make up the build
  # matrix.
  #
  # The matrix is defined in the build configuration (`.travis.yml`) and
  # expanded (evaluated and instantiated) when the Build is created.
  #
  # A build matrix has 1 to 3 dimensions and can be defined by specifying
  # multiple values for either of:
  #
  #  * a language/vm variant (e.g. 1.9.2, rbx, jruby for a Ruby build)
  #  * a dependency definition (e.g. a Gemfile for a Ruby build)
  #  * an arbitrary env key that can be used from within the test suite in
  #    order to branch out specific variations of the test run
  module Matrix
    extend ActiveSupport::Concern

    def matrix_finished?
      if matrix_config.fast_finish?
        required_jobs.all?(&:finished?) || required_jobs.any?(&:finished_unsuccessfully?)
      else
        matrix.all?(&:finished?)
      end
    end

    def matrix_duration
      matrix_finished? ? matrix.inject(0) { |duration, job| duration + job.duration.to_i } : nil
    end

    def matrix_state
      if required_jobs.blank?
        :passed
      elsif required_jobs.any?(&:canceled?)
        :canceled
      elsif required_jobs.any?(&:errored?)
        :errored
      elsif required_jobs.any?(&:failed?)
        :failed
      elsif required_jobs.all?(&:passed?)
        :passed
      else
        raise InvalidMatrixStateException.new(matrix)
      end
    end

    # expand the matrix (i.e. create test jobs) and update the config for each job
    def expand_matrix
      matrix_config.expand.each_with_index do |row, ix|
        attributes = self.attributes.slice(*Job.column_names - ['status', 'result']).symbolize_keys
        attributes.merge!(
          owner: owner,
          number: "#{number}.#{ix + 1}",
          config: row,
          log: Log.new
        )
        matrix.build(attributes)
      end
      matrix_allow_failures # TODO should be able to join this with the loop above
      matrix
    end

    def expand_matrix!
      expand_matrix
      save!
    end

    # Return only the child builds whose config matches against as passed hash
    # e.g. build.filter_matrix(rvm: '1.8.7', env: 'DB=postgresql')
    def filter_matrix(config)
      config.blank? ? matrix : matrix.select { |job| job.matches_config?(config) }
    end

    private

      def matrix_config
        @matrix_config ||= Config::Matrix.new(config, multi_os: repository.multi_os_enabled?, dist_group_expansion: repository.dist_group_expansion_enabled?)
      end

      def matrix_allow_failures
        configs = matrix_config.allow_failure_configs
        jobs = configs.map { |config| filter_matrix(config) }.flatten
        jobs.each { |job| job.allow_failure = true }
      end

      def required_jobs
        @required_jobs ||= matrix.reject { |test| test.allow_failure? }
      end
  end

  class InvalidMatrixStateException < StandardError
    attr_reader :matrix

    def initialize(matrix)
      @matrix = matrix
    end

    def to_s
      sanitized = matrix.map do |job|
        "\n\tid: #{job.id}, repository: #{job.repository.slug}, state: #{job.state}, " +
        "allow_failure: #{job.allow_failure}, " +
        "created_at: #{job.created_at.inspect}, queued_at: #{job.queued_at.inspect}, " +
        "started_at: #{job.started_at.inspect}, finished_at: #{job.finished_at.inspect}, " +
        "canceled_at: #{job.canceled_at.inspect}, updated_at: #{job.updated_at.inspect}"
      end.join

      "Invalid build matrix state detected.\nMatrix: #{sanitized}"
    end
  end
end
