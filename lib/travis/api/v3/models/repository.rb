module Travis::API::V3
  class Models::Repository < Model
    has_many :commits,     dependent: :delete_all
    has_many :requests,    dependent: :delete_all
    has_many :branches,    -> { order('branches.id DESC'.freeze) }, dependent: :delete_all
    has_many :builds,      -> { order('builds.id DESC'.freeze) }, dependent: :delete_all
    has_many :permissions, dependent: :delete_all
    has_many :users,       through:   :permissions
    has_many :stars
    has_many :email_unsubscribes

    belongs_to :owner, polymorphic: true
    belongs_to :last_build, class_name: 'Travis::API::V3::Models::Build'.freeze
    belongs_to :current_build, class_name: 'Travis::API::V3::Models::Build'.freeze

    has_one :key, class_name: 'Travis::API::V3::Models::SslKey'.freeze
    has_one :default_branch,
      foreign_key: [:repository_id, :name],
      primary_key: [:id,  :default_branch],
      class_name:  'Travis::API::V3::Models::Branch'.freeze

    alias last_started_build current_build

    after_initialize do
      update_attributes! default_branch_name: 'master'.freeze unless default_branch_name
    end

    def migrating?
      self.class.column_names.include?('migrating') && super
    end

    def migrated_at
      self.class.column_names.include?('migrated_at') && super
    end

    def slug
      @slug ||= "#{owner_name}/#{name}"
    end

    def default_branch_name
      read_attribute(:default_branch)
    end

    def default_branch_name=(value)
      write_attribute(:default_branch, value)
    end

    def default_branch
      super || branch(default_branch_name, create_without_build: true)
    end

    # Creates a branch object on the fly if it doesn't exist.
    #
    # Will not create a branch object if we don't have any builds for it unless
    # the create_without_build option is set to true.
    def branch(name, create_without_build: false)
      connection = ActiveRecord::Base.connection

      if Models::Branch.column_names.include?('unique_name') and
           connection.indexes(:branches).find {|i| i.name == "index_branches_repository_id_unique_name" }
        find_or_create_branch_with_unique_index(name: name, create_without_build: create_without_build)
      else
        legacy_find_or_create_branch(name, create_without_build: create_without_build)
      end
    end

    def find_or_create_branch_with_unique_index(name:, create_without_build: false)
      # if there are any new branches added with a unique_name we need to fetch
      # the branch with unique_name. It shouldn't happen in general, so that's
      # just a defensive code for a case when we missed a bug. If there's no
      # branch with unique_name set then just fetch whichever
      branch = branches.where(name: name).where("unique_name IS NOT NULL").first
      branch = branches.where(name: name).first unless branch
      return branch if branch

      connection = ActiveRecord::Base.connection
      quoted_id   = connection.quote(id)
      quoted_name = connection.quote(name)
      # I don't want to install any plugins for now, so I'm using raw SQL.
      # `DO UPDATE SET updated_at = now()` is used just to be able to return
      # the existing record (otherwise `RETURNING *` would not work), so that
      # we don't have to do two queries
      sql = "INSERT INTO branches (repository_id, name, exists_on_github, created_at, updated_at)
               VALUES (#{quoted_id}, #{quoted_name}, 't', now(), now())
             ON CONFLICT (repository_id, unique_name) WHERE unique_name DO NOTHING RETURNING id;"

      new_branch = false
      result = connection.execute(sql)
      if result.count > 0
        # postgresql inserted a new branch
        new_branch = true
      end

      branch = branches.where(name: name).reload.first
      return branch unless new_branch
      return nil    unless create_without_build or branch.builds.any?
      branch.last_build = branch.builds.first
      branch.save!
      branch
    end

    def legacy_find_or_create_branch(name, create_without_build: false)
      return nil    unless branch = branches.where(name: name).first_or_initialize
      return branch unless branch.new_record?
      return nil    unless create_without_build or branch.builds.any?
      branch.last_build = branch.builds.first
      branch.save!
      branch
    rescue ActiveRecord::RecordNotUnique
      branches.where(name: name).first
    end

    def id_default_branch
      [id, default_branch_name]
    end

    def send(name, *args, &block)
      if name == [:id, :default_branch]
        name = :id_default_branch
      end

      __send__(name, *args, &block)
    end

    def settings
      super || {}
    end

    def user_settings
      Models::UserSettings.new(settings).tap { |us| us.sync(self, :settings) }
    end

    def admin_settings
      Models::AdminSettings.new(settings).tap { |as| as.sync(self, :settings) }
    end

    def env_vars
      Models::EnvVars.new.tap do |ev|
        ev.load(settings.fetch('env_vars', []), repository_id: id)
        ev.sync(self, :settings)
      end
    end

    def key_pair
      return unless settings['ssh_key']
      Models::KeyPair.load(settings['ssh_key'], repository_id: id).tap do |kp|
        kp.sync(self, :settings)
      end
    end

    def debug_tools_enabled?
      return true if private?
      return true if Travis::Features.active?(:debug_tools, self)
      return false
    end

    def invalid?
      invalidated_at or owner_type.nil?
    end

    def managed_by_installation?
      !!managed_by_installation_at
    end

    def admin
      users.where(permissions: { admin: true }).with_github_token.first
    end
  end
end
