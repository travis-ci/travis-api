require "sidekiq"

begin
  require "keen"
rescue LoadError
end

module Travis
  class TravisYmlStats
    class KeenPublisher
      include ::Sidekiq::Worker

      sidekiq_options queue: :keen_events

      def perform(payload, deployment_payload = nil, notification_payload = nil)
        if defined?(Keen) && ENV["KEEN_PROJECT_ID"]
          payload = { :requests => [payload] }
          payload[:deployments] = deployment_payload if deployment_payload.to_a.size > 0
          payload[:notifications] = notification_payload if notification_payload.to_a.size > 0
          Keen.publish_batch(payload)
        end
      end
    end

    LANGUAGE_VERSION_KEYS = %w[
      ghc
      go
      jdk
      node_js
      otp_release
      perl
      php
      python
      ruby
      rvm
      scala
    ]

    def self.store_stats(request, publisher=KeenPublisher)
      new(request, publisher).store_stats
    end

    def initialize(request, publisher)
      @request = request
      @publisher = publisher
      @keen_payload = {}
      @keen_payload_deployment = []
      @keen_payload_notification = []
    end

    def store_stats
      set_basic_info
      set_language
      set_language_version
      set_uses_sudo
      set_uses_apt_get
      set_dist
      set_group
      set_deployment_provider_count
      set_notification

      @publisher.perform_async(keen_payload, keen_payload_deployment, keen_payload_notification)
    end

    private

    attr_reader :request, :keen_payload
    attr_accessor :keen_payload_deployment
    attr_accessor :keen_payload_notification

    def set(path, value, collection = keen_payload)
      path = Array(path)
      hsh = collection
      path[0..-2].each do |key|
        hsh[key.to_sym] ||= {}
        hsh = hsh[key.to_sym]
      end

      hsh[path.last.to_sym] = value
    end

    def set_basic_info
      set :event_type, request.event_type
      set :matrix_size, request.builds.map { |build| build.matrix.size }.reduce(:+)
      set :repository_id, request.repository_id
      set :owner_id, request.owner_id
      set :owner_type, request.owner_type
      # The owner_type, owner_id tuple is there so we can do unique counts on it
      set :owner, [request.owner_type, request.owner_id]
    end

    def set_language
      set :language, travis_yml_language
      set :github_language, github_language
    end

    def set_language_version
      LANGUAGE_VERSION_KEYS.each do |key|
        if config.key?(key)
          case config[key]
          when String, Array
            set [:language_version, key], Array(config[key]).map(&:to_s).sort
          else
            set [:language_version, key], ["invalid"]
          end
        end
      end
    end

    def set_uses_sudo
      set :uses_sudo, commands.any? { |command| command =~ /\bsudo\b/ }
    end

    def set_uses_apt_get
      set :uses_apt_get, commands.any? { |command| command =~ /\bapt-get\b/ }
    end

    def set_dist
      set :dist_name, dist_name
    end

    def set_group
      set :group_name, group_name
    end

    def set_deployment_provider_count
      deploy = config["deploy"] || return
      # Hash#to_a is not what we want here
      deployments = deploy.is_a?(Hash) ? [deploy] : Array(deploy)
      deployments.map {|d| d["provider"] }.uniq.each do |provider|
        keen_payload_deployment << { provider: provider.downcase, repository_id: request.repository_id }
      end
    rescue
      nil
    end

    def set_notification
      notifications = config["notifications"] || return
      notifications.keys.each do |notifier|
        keen_payload_notification << { notifier: notifier.downcase, repository_id: request.repository_id }
      end
    rescue
      nil
    end

    def config
      request.config
    end

    def payload
      request.payload.is_a?(String) ? MultiJson.decode(request.payload) : request.payload
    end

    def commands
      [
        config["before_install"],
        config["install"],
        config["before_script"],
        config["script"],
        config["after_success"],
        config["after_failure"],
        config["before_deploy"],
        config["after_deploy"],
      ].flatten.compact
    end

    def travis_yml_language
      language = config["language"]
      case language
      when String
        language
      when nil
        "default"
      else
        "invalid"
      end
    end

    def github_language
      payload.fetch("repository", {})["language"]
    end

    def normalize_string(str)
      str.downcase.gsub("#", "-sharp").gsub(/[^A-Za-z0-9.:\-_]/, "")
    end

    def dist_name
      config.fetch('dist', 'default')
    end

    def group_name
      config.fetch('group', 'default')
    end
  end
end
