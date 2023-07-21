require 'active_record'
require 'simple_states'
require 'travis/model/encrypted_column'

class RequestConfig < ActiveRecord::Base
end

# Models an incoming request. The only supported source for requests currently is Github.
#
# The Request will be configured by fetching `.travis.yml` from the Github API
# and needs to be approved based on the configuration. Once approved the
# Request creates a Build.
class Request < Travis::Model
  self.table_name = 'requests'
  include Travis::ScopeAccess
  include SimpleStates

  serialize :token, Travis::Model::EncryptedColumn.new(disable: true)

  class << self
    def columns
      super.reject { |c| c.name == 'payload' }
    end

    def last_by_head_commit(head_commit)
      where(head_commit: head_commit).order(:id).last
    end

    def older_than(id)
      recent.where('id < ?', id)
    end

    def recent(limit = 25)
      order('id DESC').limit(limit)
    end

    def with_build_id
      select('requests.*, MAX(builds.id) as build_id').
        joins('left join builds on builds.request_id = requests.id').
        group('requests.id')
    end
  end

  belongs_to :commit
  belongs_to :pull_request
  belongs_to :repository
  belongs_to :owner, polymorphic: true
  belongs_to :config, foreign_key: :config_id, class_name: 'RequestConfig'
  has_many   :builds
  has_many   :events, as: :source

  validates :repository_id, presence: true

  serialize :config
  serialize :payload

  def event_type
    read_attribute(:event_type) || 'push'
  end

  def ref
    commit.try(:ref)
  end

  def branch_name
    commit.try(:branch)
  end

  def tag_name
    ref.scan(%r{refs/tags/(.*?)$}).flatten.first if ref
  end

  def api_request?
    event_type == 'api'
  end

  def pull_request?
    event_type == 'pull_request'
  end

  def pull_request_title
    pull_request.title if pull_request
  end

  def pull_request_number
    pull_request.number if pull_request
  end

  def head_repo
    pull_request.head_repo_slug if pull_request
  end

  def base_repo
    repository.slug
  end

  def head_branch
    pull_request.head_ref if pull_request
  end

  def base_branch
    commit.branch
  end

  def config_url
    GH.full_url("repos/#{repository.slug}/contents/.travis.yml?ref=#{commit.commit}").to_s
  end

  def same_repo_pull_request?
    head_repo && base_repo && head_repo == base_repo
  rescue => e
    Travis.logger.error("[request:#{id}] Couldn't determine whether pull request is from the same repository: #{e.message}")
    false
  end

  def creates_jobs?
    Build::Config::Matrix.new(
      Build::Config.new(config).normalize, multi_os: repository.multi_os_enabled?, dist_group_expansion: repository.dist_group_expansion_enabled?
    ).expand.size > 0
  end

  def config
    record = super
    config = record&.config_json if record.respond_to?(:config_json)
    config ||= record&.config
    config ||= read_attribute(:config) if has_attribute?(:config)
    config ||= {}
    config.deep_symbolize_keys! if config.respond_to?(:deep_symbolize_keys!)
    config
  end
end
