module Features
  extend Travis::Features

  # features to hide
  OBSOLETE = %w[
    feature:big-boy:users
    feature:log_aggretation:disabled
    feature:single-build:organizations
    feature:small-plan:users
  ]

  # features to always include, even if not in db
  ALWAYS = %w[
    feature:multi_os:disabled
    feature:multi_os:repositories
    feature:education:disabled
    feature:osx_alt_image:disabled
    feature:osx_alt_image:repositories
  ]

  # hidden if not enabled
  HIDDEN = %w[
    ey-plan
    big-boy-plan
    neckbeard-plan
    cancel-subscription
  ]

  class << self
    def count(kind, feature)
      ids(kind, feature).size
    end

    def for(object)
      results = for_kind(object.class).map { |key| [key, owner_active?(key, object)] }
      Hash[results].reject { |key, value| !value && HIDDEN.include?(key) }
    end

    def for_kind(kind)
      kind      = kind.table_name unless kind.is_a?(String)
      features  = feature_keys.grep(/feature:([^:]+):#{kind}/) { $1 }.sort
      features += for_kind('users').grep(/-plan$/) if kind == 'organizations'
      features.uniq.sort
    end

    def global
      results = for_kind('disabled').map { |key| [key, feature_active?(key)] }
      Hash[results]
    end

    def members(kind, feature)
      kind = kind.singularize.camelize.constantize if kind.is_a?(String)
      kind.where(id: ids(kind, feature))
    end

    def reload
      @feature_keys = nil
    end

    private

    def feature_keys
      # scan_each call may take a few seconds, but is cached after that
      # see also https://github.com/travis-pro/post-its/issues/172
      @feature_keys ||= redis.scan_each(match: 'feature:*', count: 600).to_a - OBSOLETE + ALWAYS
    end

    def ids(kind, feature)
      kind = kind.table_name unless kind.is_a?(String)
      redis.smembers("feature:#{feature}:#{kind}")
    end
  end
end
