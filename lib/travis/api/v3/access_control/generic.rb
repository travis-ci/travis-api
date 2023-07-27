module Travis::API::V3
  class AccessControl::Generic
    def self.for_request(type, payload, env)
    end

    def self.auth_type(*list)
      list.each { |e| (AccessControl::REGISTER[e] ||= []) << self }
    end

    def visible?(object, type = nil)
      full_access? or dispatch(object, :visible?, type)
    end

    def cancelable?(object)
      full_access? or dispatch(object, :cancelable?)
    end

    def restartable?(object)
      full_access? or dispatch(object, :restartable?)
    end

    def starable?(object)
      full_access? or dispatch(object, :starable?)
    end

    def writable?(object)
      full_access? or dispatch(object, :writable?)
    end

    def adminable?(object)
      dispatch(object, :adminable?)
    end

    def admin_for(repository)
      raise AdminAccessRequired, repository: repository
    end

    def user
    end

    def logged_in?
      false
    end

    def full_access?
      false
    end

    def temp_access?
      false
    end

    def full_access_or_logged_in?
      full_access? || logged_in?
    end

    def enterprise?
      !!Travis.config.enterprise
    end

    def force_auth?
      !!Travis.config.force_authentication
    end

    def visible_repositories(list, repository_id = nil)
      # naïve implementation, can be replaced with smart implementation in specific subclasses
      visible_objects(list, repository_id, Models::Repository)
    end

    def visible_builds(list, repository_id = nil)
      # naïve implementation, can be replaced with smart implementation in specific subclasses
      visible_objects(list, repository_id, Models::Build)
    end

    def visible_jobs(list, repository_id = nil)
      # naïve implementation, can be replaced with smart implementation in specific subclasses
      visible_objects(list, repository_id, Models::Job)
    end

    def visible_requests(list, repository_id = nil)
      # naïve implementation, can be replaced with smart implementation in specific subclasses
      visible_objects(list, repository_id, Models::Request)
    end

    def permissions(object)
      return unless factory = permission_class(object.class)
      factory.new(self, object)
    end

    protected

    def account_visible?(account)
      user and account.members.include?(user)
    end

    def build_visible?(build)
      repository_visible? build.repository, !build.private?
    end

    def build_writable?(build)
      writable? build.repository
    end

    def branch_visible?(branch)
      visible? branch.repository
    end

    def cron_visible?(cron)
      visible? cron.branch
    end

    def cron_writable?(cron)
      writable? cron.branch.repository
    end

    def installation_visible?(installation)
      visible? installation.owner
    end

    def log_visible?(log)
      visible? log.job
    end

    def job_visible?(job)
      repository_visible? job.repository, !job.private?
    end

    def job_cancelable?(job)
      cancelable? job.repository
    end

    def job_restartable?(job)
      restartable? job.repository
    end

    def job_writable?(job)
      writable? job.repository
    end

    def key_pair_visible?(key_pair)
      visible? key_pair.repository
    end

    def preferences_visible?(preferences)
      adminable? preferences.parent
    end
    alias_method :user_preferences_visible?, :preferences_visible?
    alias_method :organization_preferences_visible?, :preferences_visible?
    alias_method :preference_visible?, :preferences_visible?

    def organization_visible?(organization)
      full_access? or public_mode?(organization)
    end

    def organization_adminable?(organization)
      full_access? or organization.memberships.where(user: self.user, role: 'admin').exists?
    end

    def ssl_key_visible?(ssl_key)
      visible? ssl_key.repository
    end

    def ssl_key_writable?(ssl_key)
      writable? ssl_key.repository
    end

    def user_visible?(user)
      unrestricted_api?(user) || logged_in?
    end

    def user_writable?(user)
      self.user == user
    end

    def user_adminable?(user)
      user_writable?(user)
    end

    def is_current_user?(user)
      self.user == user
    end

    def beta_features_visible?(user)
      is_current_user?(user)
    end
    alias_method :beta_feature_visible?, :beta_features_visible?

    def user_setting_visible?(user_setting)
      visible? user_setting.repository
    end

    def repository_adminable?(repository)
      false
    end

    def repository_starable?(repository)
      false
    end

    def repository_visible?(repository, show_public = true)
      return false if repository.invalid?

      return true  if show_public and unrestricted_api?(repository.owner) and not repository.private?
      private_repository_visible?(repository)
    end

    def request_visible?(request)
      repository_visible? request.repository, !request.private?
    end

    def private_repository_visible?(repository)
      false
    end

    def repository_attr_visible?(record)
      repository_visible?(record.repository)
    end
    [:settings_visible?, :env_vars_visible?, :env_var_visible?, :key_pairs_visible?].each do |m|
      alias_method m, :repository_attr_visible?
    end

    def public_mode?(owner = nil)
      Travis.config.public_mode || owner && Travis::Features.owner_active?(:public_mode, owner)
    end

    def unrestricted_api?(owner = nil)
      full_access? or public_mode?(owner)
    end

    private

    def dispatch(object, method, type = nil)
      method = method_for(type || object.class, method)
      send(method, object) if respond_to?(method, true)
    end


    @@unknown_permission     = Object.new
    @@permission_class_cache = Tool::ThreadLocal.new
    @@method_for_cache       = Tool::ThreadLocal.new

    def permission_class(klass)
      result = @@permission_class_cache[klass] ||= Permissions[normalize_type(klass), false] || @@unknown_permission
      result unless result == @@unknown_permission
    end

    def method_for(type, method)
      type_cache = @@method_for_cache[type] ||= {}
      type_cache[method]                    ||= "#{normalize_type(type)}_#{method}"
    end

    def normalize_type(type)
      if type.is_a?(Symbol)
        type
      else
        type.name.sub(/^Travis::API::V3::Models::/, ''.freeze).underscore.to_sym
      end
    end

    def visible_objects(list, repository_id, factory)
      return list if full_access?
      list.select { |r| visible?(r) }
    end
  end
end
