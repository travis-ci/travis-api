require 'active_support/concern'
require 'simple_states'

class Request
  module States
    extend ActiveSupport::Concern
    include Travis::Event

    included do
      include SimpleStates

      states :created, :started, :finished
      event :start,     :to => :started, :after => :configure
      event :configure, :to => :configured, :after => :finish
      event :finish,    :to => :finished
      event :all, :after => :notify
    end

    def configure
      if !accepted?
        Travis.logger.warn("[request:configure] Request not accepted: event_type=#{event_type.inspect} commit=#{commit.try(:commit).inspect} message=#{approval.message.inspect}")
      else
        self.config = fetch_config.merge(config || {})

        if branch_accepted? && config_accepted?
          Travis.logger.info("[request:configure] Request successfully configured commit=#{commit.commit.inspect}")
        else
          self.config = nil
          Travis.logger.warn("[request:configure] Request not accepted: event_type=#{event_type.inspect} commit=#{commit.try(:commit).inspect} message=#{approval.message.inspect}")
        end
      end
      save!
    end

    def finish
      if config.blank?
        Travis.logger.warn("[request:finish] Request not creating a build: config is blank or contains YAML syntax error, config=#{config.inspect} commit=#{commit.try(:commit).inspect}")
      elsif !approved?
        Travis.logger.warn("[request:finish] Request not creating a build: not approved commit=#{commit.try(:commit).inspect} message=#{approval.message.inspect}")
      elsif parse_error?
        Travis.logger.info("[request:finish] Request created but Build and Job automatically errored due to a config parsing error. commit=#{commit.try(:commit).inspect}")
        add_parse_error_build
      elsif server_error?
        Travis.logger.info("[request:finish] Request created but Build and Job automatically errored due to a config server error. commit=#{commit.try(:commit).inspect}")
        add_server_error_build
      else
        add_build_and_notify
        Travis.logger.info("[request:finish] Request created a build. commit=#{commit.try(:commit).inspect}")
      end
      self.result = approval.result
      self.message = approval.message
      Travis.logger.info("[request:finish] Request finished. result=#{result.inspect} message=#{message.inspect} commit=#{commit.try(:commit).inspect}")
    end

    def add_build
      builds.create!(:repository => repository, :commit => commit, :config => config, :owner => owner)
    end

    def add_build_and_notify
      add_build.tap do |build|
        build.notify(:created) if Travis.config.notify_on_build_created
      end
    end

    protected

      delegate :accepted?, :approved?, :branch_accepted?, :config_accepted?, :to => :approval

      def approval
        @approval ||= Approval.new(self)
      end

      def fetch_config
        Travis.run_service(:github_fetch_config, request: self) # TODO move to a service, have it pass the config to configure
      end

      def add_parse_error_build
        Build.transaction do
          build = add_build
          job = build.matrix.first
          job.start!(started_at: Time.now.utc)
          job.log_content = <<ERROR
\033[31;1mERROR\033[0m: An error occured while trying to parse your .travis.yml file.

Please make sure that the file is valid YAML.

http://lint.travis-ci.org can check your .travis.yml.

The error was "#{config[".result_message"]}".
ERROR
          job.finish!(state: "errored",   finished_at: Time.now.utc)
          build.finish!(state: "errored", finished_at: Time.now.utc)
        end
      end

      def parse_error?
        config[".result"] == "parse_error"
      end

      def add_server_error_build
        Build.transaction do
          build = add_build
          job = build.matrix.first
          job.start!(started_at: Time.now.utc)
          job.log_content = <<ERROR
\033[31;1mERROR\033[0m: An error occured while trying to fetch your .travis.yml file.

Is GitHub down? Please contact support@travis-ci.com if this persists.
ERROR
          job.finish!(state: "errored",   finished_at: Time.now.utc)
          build.finish!(state: "errored", finished_at: Time.now.utc)
        end
      end

      def server_error?
        config[".result"] == "server_error"
      end
  end
end
