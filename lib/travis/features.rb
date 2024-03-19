require 'redis'
require 'rollout'
require 'active_support/deprecation'
require 'active_support/core_ext/module'

module Travis
  # Travis::Features contains methods to handle feature flags.
  module Features
    class << self
      methods = (Rollout.public_instance_methods(false) - [:active?, "active?"])
      delegate(*methods, to: :rollout)
    end

    def redis
      Travis.redis
    end

    def rollout
      @rollout ||= ::Rollout.new(redis)
    end

    # Returns whether a given feature is enabled either globally or for a given
    # repository.
    #
    # By default, this will return false.
    def active?(feature, repository)
      feature_active?(feature) or
        (rollout.active?(feature, repository.owner) or
          repository_active?(feature, repository))
    end

    def activate_repository(feature, repository)
      redis.sadd(repository_key(feature), repository_id(repository))
    end

    def deactivate_repository(feature, repository)
      redis.srem(repository_key(feature), repository_id(repository))
    end

    # Return whether a given feature is enabled for a repository.
    #
    # By default, this will return false.
    def repository_active?(feature, repository)
      repository_id(repository) && redis.sismember(repository_key(feature), repository_id(repository))
    end

    # Return whether a given feature is enabled for a user.
    #
    # By default, this will return false.
    def user_active?(feature, user)
      rollout.active?(feature, user)
    end

    def activate_all(feature)
      redis.del(disabled_key(feature))
    end

    # Return whether a feature is enabled globally.
    #
    # By default, this will return false.
    def feature_active?(feature)
      enabled_for_all?(feature) and !feature_inactive?(feature)
    end

    # Return whether a feature has been disabled.
    #
    # This is similar to feature_deactivated?, but with the opposite default.
    #
    # By default this will return true (ie. disabled).
    def feature_inactive?(feature)
      redis.get(disabled_key(feature)) != "1"
    end

    # Return whether a feature has been disabled.
    #
    # This is similar to feature_inactive?, but with the opposite default.
    #
    # By default this will return false (ie not disabled).
    def feature_deactivated?(feature)
      redis.get(disabled_key(feature)) == '0'
    end

    def deactivate_all(feature)
      redis.set(disabled_key(feature), 0)
    end

    # Return whether a feature has been enabled globally.
    #
    # By default this will return false.
    def enabled_for_all?(feature)
      redis.get(enabled_for_all_key(feature)) == '1'
    end

    def enable_for_all(feature)
      redis.set(enabled_for_all_key(feature), 1)
    end

    def disable_for_all(feature)
      redis.set(enabled_for_all_key(feature), 0)
    end

    def activate_owner(feature, owner)
      redis.sadd(owner_key(feature, owner), owner.id)
    end

    def deactivate_owner(feature, owner)
      redis.srem(owner_key(feature, owner), owner.id)
    end

    # Return whether a feature has been enabled for a user.
    #
    # By default, this return false.
    def owner_active?(feature, owner)
      return false unless owner
      redis.sismember(owner_key(feature, owner), owner.id)
    end

    extend self

    private

    def key(name)
      "feature:#{name}"
    end

    def owner_key(feature, owner)
      suffix = owner.class.table_name if owner
      "#{key(feature)}:#{suffix}"
    end

    def repository_key(feature)
      "#{key(feature)}:repositories"
    end

    def disabled_key(feature)
      "#{key(feature)}:disabled"
    end

    def enabled_for_all_key(feature)
      # TODO: this should be :enabled, changing it could break things though
      "#{key(feature)}:disabled"
    end

    def repository_id(repository)
      repository.respond_to?(:id) ? repository.id : repository.to_i
    end
  end
end
