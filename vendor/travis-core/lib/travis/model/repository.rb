require 'uri'
require 'core_ext/hash/compact'
require 'travis/model'

# Models a repository that has many builds and requests.
#
# A repository has an ssl key pair that is used to encrypt and decrypt
# sensitive data contained in the public `.travis.yml` file, such as Campfire
# authentication data.
#
# A repository also has a ServiceHook that can be used to de/activate service
# hooks on Github.
class Repository < Travis::Model
  require 'travis/model/repository/status_image'
  require 'travis/model/repository/settings'

  has_many :commits, dependent: :delete_all
  has_many :requests, dependent: :delete_all
  has_many :builds, dependent: :delete_all
  has_many :events
  has_many :permissions, dependent: :delete_all
  has_many :users, through: :permissions

  has_one :last_build, class_name: 'Build', order: 'id DESC'
  has_one :key, class_name: 'SslKey'
  belongs_to :owner, polymorphic: true

  validates :name,       presence: true
  validates :owner_name, presence: true

  before_create do
    build_key
  end

  delegate :public_key, to: :key

  class << self
    def timeline
      active.order('last_build_finished_at IS NULL AND last_build_started_at IS NOT NULL DESC, last_build_started_at DESC NULLS LAST, id DESC')
    end

    def with_builds
      where(arel_table[:last_build_id].not_eq(nil))
    end

    def administratable
      includes(:permissions).where('permissions.admin = ?', true)
    end

    def recent
      limit(25)
    end

    def by_owner_name(owner_name)
      without_invalidated.where(owner_name: owner_name)
    end

    def by_member(login)
      without_invalidated.joins(:users).where(users: { login: login })
    end

    def by_slug(slug)
      without_invalidated.where(owner_name: slug.split('/').first, name: slug.split('/').last).order('id DESC')
    end

    def search(query)
      query = query.gsub('\\', '/')
      without_invalidated.where("(repositories.owner_name || chr(47) || repositories.name) ILIKE ?", "%#{query}%")
    end

    def active
      without_invalidated.where(active: true)
    end

    def without_invalidated
      where(invalidated_at: nil)
    end

    def find_by(params)
      if id = params[:repository_id] || params[:id]
        find_by_id(id)
      elsif params[:github_id]
        find_by_github_id(params[:github_id])
      elsif params.key?(:slug)
        by_slug(params[:slug]).first
      elsif params.key?(:name) && params.key?(:owner_name)
        by_slug("#{params[:owner_name]}/#{params[:name]}").first
      end
    end

    def by_name
      Hash[*all.map { |repository| [repository.name, repository] }.flatten]
    end

    def counts_by_owner_names(owner_names)
      query = %(SELECT owner_name, count(*) FROM repositories WHERE owner_name IN (?) AND invalidated_at IS NULL GROUP BY owner_name)
      query = sanitize_sql([query, owner_names])
      rows = connection.select_all(query, owner_names)
      Hash[*rows.map { |row| [row['owner_name'], row['count'].to_i] }.flatten]
    end
  end

  delegate :builds_only_with_travis_yml?, to: :settings

  def admin
    @admin ||= Travis.run_service(:find_admin, repository: self) # TODO check who's using this
  end

  def slug
    @slug ||= [owner_name, name].join('/')
  end

  def api_url
    "#{Travis.config.github.api_url}/repos/#{slug}"
  end

  def source_url
    (private? || private_mode?) ? "git@#{source_host}:#{slug}.git": "git://#{source_host}/#{slug}.git"
  end

  def private_mode?
    source_host != 'github.com'
  end

  def source_host
    Travis.config.github.source_host || 'github.com'
  end

  def branches
    self.class.connection.select_values %(
      SELECT DISTINCT ON (branch) branch
      FROM   builds
      WHERE  builds.repository_id = #{id}
      ORDER  BY branch DESC
      LIMIT  25
    )
  end

  def last_completed_build(branch = nil)
    builds.api_and_pushes.last_build_on(state: [:passed, :failed, :errored, :canceled], branch: branch)
  end

  def last_build_on(branch)
    builds.api_and_pushes.last_build_on(branch: branch)
  end

  def build_status(branch)
    builds.api_and_pushes.last_state_on(state: [:passed, :failed, :errored, :canceled], branch: branch)
  end

  def last_finished_builds_by_branches(limit = 50)
    Build.joins(%(
      inner join (
        select distinct on (branch) builds.id
        from   builds
        where  builds.repository_id = #{id} and builds.event_type = 'push'
        order  by branch, finished_at desc
      ) as last_builds on builds.id = last_builds.id
    )).limit(limit).order('finished_at DESC')
  end

  def regenerate_key!
    ActiveRecord::Base.transaction do
      key.destroy unless key.nil?
      build_key
      save!
    end
  end

  def settings
    @settings ||= begin
      instance = Repository::Settings.load(super, repository_id: id)
      instance.on_save do
        self.settings = instance.to_json
        self.save!
      end
      instance
    end
  end

  def settings=(value)
    if value.is_a?(String) || value.nil?
      super(value)
    else
      super(value.to_json)
    end
  end

  def users_with_permission(permission)
    users.includes(:permissions).where(permissions: { permission => true }).limit(10).all
  end

  def reload(*)
    @settings = nil
    super
  end

  def multi_os_enabled?
    Travis::Features.enabled_for_all?(:multi_os) || Travis::Features.active?(:multi_os, self)
  end

  def dist_group_expansion_enabled?
    Travis::Features.enabled_for_all?(:dist_group_expansion) || Travis::Features.active?(:dist_group_expansion, self)
  end

end
