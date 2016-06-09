module Travis::API::V3
  class AccessControl::Generic
    def self.for_request(type, payload, env)
    end

    def self.auth_type(*list)
      list.each { |e| (AccessControl::REGISTER[e] ||= []) << self }
    end

    def visible?(object)
      full_access? or dispatch(object, :visible?)
    end

    def writable?(object)
      full_access? or dispatch(object, :writable?)
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

    def visible_repositories(list)
      # naïve implementation, replaced with smart implementation in specific subclasses
      return list if full_access?
      list.select { |r| visible?(r) }
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
      visible? build.repository
    end

    def build_writable?(build)
      writable? build.repository
    end

    def branch_visible?(branch)
      visible? branch.repository
    end

    def cron_visible?(cron)
      Travis::Features.owner_active?(:cron, cron.branch.repository.owner) and visible? cron.branch.repository
    end

    def cron_writable?(cron)
      Travis::Features.owner_active?(:cron, cron.branch.repository.owner) and writable? cron.branch.repository
    end

    def job_visible?(job)
      visible? job.repository
    end

    def job_writable?(job)
      writable? job.repository
    end

    def organization_visible?(organization)
      full_access? or public_api?
    end

    def user_visible?(user)
      unrestricted_api?
    end

    def user_writable?(user)
      self.user == user
    end

    def repository_visible?(repository)
      return true if unrestricted_api? and not repository.private?
      private_repository_visible?(repository)
    end

    def settings_visible?(settings)
      repository_visible?(settings.repository)
    end

    def private_repository_visible?(repository)
      false
    end

    def public_api?
      !Travis.config.private_api
    end

    def unrestricted_api?
      full_access? or logged_in? or public_api?
    end

    private

    def dispatch(object, method)
      method = method_for(object.class, method)
      send(method, object) if respond_to?(method, true)
    end


    @@unknown_permission     = Object.new
    @@permission_class_cache = Tool::ThreadLocal.new
    @@method_for_cache       = Tool::ThreadLocal.new

    def permission_class(klass)
      result = @@permission_class_cache[klass] ||= Permissions[normailze_type(klass), false] || @@unknown_permission
      result unless result == @@unknown_permission
    end

    def method_for(type, method)
      type_cache = @@method_for_cache[type] ||= {}
      type_cache[method]                    ||= "#{normailze_type(type)}_#{method}"
    end

    def normailze_type(type)
      type.name.sub(/^Travis::API::V3::Models::/, ''.freeze).underscore.to_sym
    end
  end
end
