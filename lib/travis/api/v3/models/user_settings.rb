module Travis::API::V3
  class Models::UserSettings < Travis::Settings::Model
    include Enumerable

    attribute :builds_only_with_travis_yml, Boolean, default: false
    attribute :build_pushes, Boolean, default: true
    attribute :build_pull_requests, Boolean, default: true
    attribute :maximum_number_of_builds, Integer, default: 0

    def each(&block)
      return enum_for(:each) unless block_given?
      attributes.keys.each { |name| yield setting(name) }
      self
    end

    def setting(name)
      value = send(name)
      Models::UserSetting.new(name, value) unless value.nil?
    end
  end

  class Models::UserSetting < Struct.new(:name, :value)
    def public?
      true
    end
  end
end
