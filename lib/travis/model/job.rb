require 'travis/model'
require 'travis/config/defaults'
require 'active_support/core_ext/object/deep_dup'
require 'travis/model/build/config/language'

class JobConfig < ActiveRecord::Base
end

class Job < Travis::Model
  self.table_name = 'jobs'
  require 'travis/model/job/queue'
  require 'travis/model/job/test'
  require 'travis/model/env_helpers'

  include Travis::ScopeAccess

  SAFELISTED_ADDONS = %w(
    apt
    apt_packages
    apt_sources
    chrome
    firefox
    hosts
    mariadb
    postgresql
    ssh_known_hosts
  ).freeze

  class << self
    # what we return from the json api
    def queued(queue = nil)
      scope = where(state: [:created, :queued])
      scope = scope.where(queue: queue) if queue
      scope
    end

    # what needs to be queued up
    def queueable(queue = nil)
      scope = where(state: :created).order('jobs.id')
      scope = scope.where(queue: queue) if queue
      scope
    end

    # what already is queued or started
    def running(queue = nil)
      scope = where(state: [:queued, :received, :started]).order('jobs.id')
      scope = scope.where(queue: queue) if queue
      scope
    end

    def unfinished
      # TODO conflate Job and Job::Test and use States::FINISHED_STATES
      where('state NOT IN (?)', [:finished, :passed, :failed, :errored, :canceled])
    end

    def owned_by(owner)
      where(owner_id: owner.id, owner_type: owner.class.to_s)
    end
  end

  include Travis::Model::EnvHelpers

  has_many   :events, as: :source

  belongs_to :repository
  belongs_to :commit
  belongs_to :source, polymorphic: true, autosave: true
  belongs_to :owner, polymorphic: true
  belongs_to :config, foreign_key: :config_id, class_name: 'JobConfig'

  validates :repository_id, :commit_id, :source_id, :source_type, :owner_id, :owner_type, presence: true

  serialize :config

  delegate :request_id, to: :source # TODO denormalize
  delegate :pull_request?, to: :commit
  delegate :secure_env_enabled?, :addons_enabled?, to: :source

  before_create do
    self.state = :created if self.state.nil?
    self.queue = Queue.for(self).name
  end

  after_commit on: :create do
    notify(:create) if respond_to?(:notify)
  end

  def propagate(name, *args)
    # if we propagate cancel, we can't send it as "cancel", because
    # it would trigger cancelling the entire matrix
    if name == :cancel
      name = :cancel_job
    end
    Metriks.timer("job.propagate.#{name}").time do
      source.send(name, *args)
    end
    true
  end

  def state
    (super || :created).to_sym
  end

  def migrated?
    !!org_id
  end

  def restarted?
    !!restarted_at
  end

  def restarted_post_migration?
    restarted? && restarted_at > repository.migrated_at
  end

  def duration
    return 0 if started_at && finished_at && started_at > finished_at
    started_at && finished_at ? finished_at - started_at : nil
  end

  def ssh_key
    config[:source_key]
  end

  def config=(config)
    return super if config.nil?
    raise unless ENV['RACK_ENV'] == 'test'
    config = normalize_config(config)
    config = JobConfig.new(repository_id: repository_id, key: 'key', config: config)
    super(config)
  end

  def config
    record = super
    config = record&.config_json if record.respond_to?(:config_json)
    config ||= record&.config
    config ||= read_attribute(:config) if has_attribute?(:config)
    config ||= {}
    config = JSON.parse(config) if config.is_a?(String)
    config.deep_symbolize_keys! if config.respond_to?(:deep_symbolize_keys!)
    config
  end

  def obfuscated_config
    normalize_config(config).deep_dup.tap do |config|
      delete_addons(config)
      config.delete(:source_key)
      if config[:env]
        obfuscated_env = process_env(config[:env]) { |env| obfuscate_env(env) }
        config[:env] = obfuscated_env ? obfuscated_env.join(' ') : nil
      end
      if config[:global_env]
        obfuscated_env = process_env(config[:global_env]) { |env| obfuscate_env(env) }
        config[:global_env] = obfuscated_env ? obfuscated_env.join(' ') : nil
      end
    end
  end

  def decrypted_config
    normalize_config(self.config).deep_dup.tap do |config|
      config[:env] = process_env(config[:env]) { |env| decrypt_env(env) } if config[:env]
      config[:global_env] = process_env(config[:global_env]) { |env| decrypt_env(env) } if config[:global_env]
      if config[:addons]
        if addons_enabled?
          config[:addons] = decrypt_addons(config[:addons])
        else
          delete_addons(config)
        end
      end
    end
  rescue => e
    logger.warn "[job id:#{id}] Config could not be decrypted due to #{e.message}"
    {}
  end

  def matches_config?(other)
    config = self.config.slice(*other.keys)
    config = config.merge(branch: commit.branch) if other.key?(:branch) # TODO test this
    return false if config.size == 0
    config.all? { |key, value| value == other[key] || commit.branch == other[key] }
  end

  def log_content=(content)
    Travis::RemoteLog.write_content_for_job_id(id, content: content)
  end

  def log
    @log ||= Travis::RemoteLog::Remote.new.find_by_job_id(id)
  end

  attr_writer :log

  def log_id
    @log_id ||= Travis::RemoteLog::Remote.new.find_id_by_job_id(id)
  end

  attr_writer :log_id

  # compatibility, we still use result in webhooks
  def result
    state.try(:to_sym) == :passed ? 0 : 1
  end

  private

    def delete_addons(config)
      if config[:addons].is_a?(Hash)
        config[:addons].keep_if { |key, _| SAFELISTED_ADDONS.include? key.to_s }
      else
        config.delete(:addons)
      end
    end

    def normalize_config(config)
      config = YAML.load(config, aliases: true) if config.is_a? String
      config = config ? config.deep_symbolize_keys : {}

      if config[:deploy]
        if config[:addons].is_a? Hash
          config[:addons][:deploy] = config.delete(:deploy)
        else
          config.delete(:addons)
          config[:addons] = { deploy: config.delete(:deploy) }
        end
      end

      config
    end

    def process_env(env)
      env = env.to_s if env.is_a?(Float)
      env = [env] unless env.is_a?(Array)
      env = normalize_env(env)
      env = if secure_env_enabled?
        yield(env)
      else
        remove_encrypted_env_vars(env)
      end
      env.compact.presence
    end

    def remove_encrypted_env_vars(env)
      env.reject do |var|
        var.is_a?(Hash) && var.has_key?(:secure)
      end
    end

    def normalize_env(env)
      env.map do |line|
        if line.is_a?(Hash) && !line.has_key?(:secure)
          line.map { |k, v| "#{k}=#{v}" }.join(' ')
        else
          line
        end
      end
    end

    def decrypt_addons(addons)
      decrypt(addons)
    end

    def decrypt_env(env)
      env.map do |var|
        decrypt(var) do |var|
          var.dup.insert(0, 'SECURE ') unless var.include?('SECURE ')
        end
      end
    rescue
      {}
    end

    def decrypt(v, &block)
      repository.key.secure.decrypt(v, &block)
    end
end
