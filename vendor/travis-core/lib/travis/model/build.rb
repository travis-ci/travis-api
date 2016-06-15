require 'core_ext/hash/deep_symbolize_keys'
require 'simple_states'
require 'travis/model'
require 'travis/services/next_build_number'

# Build currently models a central but rather abstract domain entity: the thing
# that is triggered by a Github request (service hook ping).
#
# Build groups a matrix of Job::Test instances, and belongs to a Request (and
# thus Commit as well as a Repository).
#
# A Build is created when its Request was configured (by fetching .travis.yml)
# and approved (e.g. not excluded by the configuration). Once a Build is
# created it will expand its matrix according to the given configuration and
# create the according Job::Test instances.  Each Job::Test instance will
# trigger a test run remotely (on the worker). Once all Job::Test instances
# have finished the Build will be finished as well.
#
# Each of these state changes (build:created, job:started, job:finished, ...)
# will issue events that are listened for by the event handlers contained in
# travis/notification. These event handlers then send out various notifications
# of various types through email, pusher and irc, archive builds and queue
# jobs for the workers.
#
# Build is split up to several modules:
#
#  * Build       - ActiveRecord structure, validations and scopes
#  * States      - state definitions and events
#  * Denormalize - some state changes denormalize attributes to the build's
#                  repository (e.g. Build#started_at gets propagated to
#                  Repository#last_started_at)
#  * Matrix      - logic related to expanding the build matrix, normalizing
#                  configuration for Job::Test instances, evaluating the
#                  final build result etc.
#  * Messages    - helpers for evaluating human readable result messages
#                  (e.g. "Still Failing")
#  * Events      - helpers that are used by notification handlers (and that
#                  TODO probably should be cleaned up and moved to
#                  travis/notification)
class Build < Travis::Model
  require 'travis/model/build/config'
  require 'travis/model/build/denormalize'
  require 'travis/model/build/update_branch'
  require 'travis/model/build/matrix'
  require 'travis/model/build/metrics'
  require 'travis/model/build/result_message'
  require 'travis/model/build/states'
  require 'travis/model/env_helpers'

  include Matrix, States, SimpleStates

  belongs_to :commit
  belongs_to :request
  belongs_to :repository, autosave: true
  belongs_to :owner, polymorphic: true
  has_many   :matrix, as: :source, order: :id, class_name: 'Job::Test', dependent: :destroy
  has_many   :events, as: :source

  validates :repository_id, :commit_id, :request_id, presence: true

  serialize :config

  delegate :same_repo_pull_request?, :to => :request

  class << self
    def recent
      where(state: ['failed', 'passed']).order('id DESC').limit(25)
    end

    def running
      where(state: ['started']).order('started_at DESC')
    end

    def was_started
      where('state <> ?', :created)
    end

    def finished
      where(state: [:finished, :passed, :failed, :errored, :canceled]) # TODO extract
    end

    def on_state(state)
      where(state.present? ? ['builds.state IN (?)', state] : [])
    end

    def on_branch(branch)
      api_and_pushes.where(branch.present? ? ['branch IN (?)', normalize_to_array(branch)] : [])
    end

    def by_event_type(event_types)
      event_types = Array(event_types).flatten
      event_types << 'push' if event_types.empty?
      where(event_type: event_types)
    end

    def pushes
      where(event_type: 'push')
    end

    def pull_requests
      where(event_type: 'pull_request')
    end

    def api_and_pushes
      by_event_type(['api', 'push'])
    end

    def previous(build)
      where('builds.repository_id = ? AND builds.id < ?', build.repository_id, build.id).finished.descending.limit(1).first
    end

    def descending
      order(arel_table[:id].desc)
    end

    def paged(options)
      page = (options[:page] || 1).to_i
      limit(per_page).offset(per_page * (page - 1))
    end

    def last_build_on(options)
      scope = descending
      scope = scope.on_state(options[:state])   if options[:state]
      scope = scope.on_branch(options[:branch]) if options[:branch]
      scope.first
    end

    def last_state_on(options)
      last_build_on(options).try(:state).try(:to_sym)
    end

    def older_than(build = nil)
      scope = order('number::integer DESC').paged({}) # TODO in which case we'd call older_than without an argument?
      scope = scope.where('number::integer < ?', (build.is_a?(Build) ? build.number : build).to_i) if build
      scope
    end

    protected

      def normalize_to_array(object)
        Array(object).compact.join(',').split(',')
      end

      def per_page
        25
      end
  end

  # set the build number and expand the matrix; downcase language
  before_create do
    next_build_number = Travis::Services::NextBuildNumber.new(repository_id: repository.id).run
    self.number = next_build_number
    self.previous_state = last_finished_state_on_branch
    self.event_type = request.event_type
    self.pull_request_title = request.pull_request_title
    self.pull_request_number = request.pull_request_number
    self.branch = commit.branch
    expand_matrix
  end

  after_create do
    UpdateBranch.new(self).update_last_build unless pull_request?
  end

  after_save do
    unless cached_matrix_ids
      update_column(:cached_matrix_ids, to_postgres_array(matrix_ids))
    end
  end

  # AR 3.2 does not handle pg arrays and the plugins supporting them
  # do not work well with jdbc drivers
  # TODO: remove this once we're on >= 4.0
  def cached_matrix_ids
    if (value = super) && value =~ /^{/
      value.gsub(/^{|}$/, '').split(',').map(&:to_i)
    end
  end

  def matrix_ids
    matrix.map(&:id)
  end

  def secure_env_enabled?
    !pull_request? || same_repo_pull_request?
  end
  alias addons_enabled? secure_env_enabled?

  def config=(config)
    super((config || {}).deep_symbolize_keys)
  end

  def config
    @config ||= Config.new(super, multi_os: repository.multi_os_enabled?).normalize
  end

  def obfuscated_config
    Config.new(config, key_fetcher: lambda { self.repository.key }).obfuscate
  end

  def cancelable?
    matrix.any? { |job| job.cancelable? }
  end

  def pull_request?
    event_type == 'pull_request'
  end

  # COMPAT: used in http api v1, deprecate as soon as v1 gets retired
  def result
    state.try(:to_sym) == :passed ? 0 : 1
  end

  def on_default_branch?
    branch == repository.default_branch
  end

  private

    def last_finished_state_on_branch
      repository.builds.finished.last_state_on(branch: commit.branch)
    end

    def to_postgres_array(ids)
      ids = ids.compact.uniq
      "{#{ids.map { |id| id.to_i.to_s }.join(',')}}" unless ids.empty?
    end
end
