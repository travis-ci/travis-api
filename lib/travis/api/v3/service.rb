require 'travis/remote_vcs/repository'

module Travis::API::V3
  class Service
    DEFAULT_PARAMS = [ "include".freeze, "@type".freeze, 'representation'.freeze ]
    private_constant :DEFAULT_PARAMS

    def self.result_type(rt = nil)
      @result_type   = rt if rt
      @result_type ||= module_parent.result_type if module_parent and module_parent.respond_to? :result_type
      raise 'result type not set' unless defined? @result_type
      @result_type
    end

    def self.type(t = nil)
      @type ||= (t || result_type)
    end

    def self.filter_params(params)
      wanted = self.params
      params.select { |key| wanted.include? key }
    end

    def self.params(*list, prefix: nil)
      @params ||= superclass.respond_to?(:params) ? superclass.params.dup : DEFAULT_PARAMS
      list.each do |entry|
        @params << entry.to_s
        @params << "#{prefix || result_type}.#{entry}" if entry.is_a? Symbol
      end
      @params
    end

    def self.accepted_params
      self.params.select { |p| p =~ /#{type}\./.freeze }
    end

    def self.paginate(**options)
      params("limit".freeze, "offset".freeze, "skip_count".freeze)
      params("sort_by".freeze) if query_factory.sortable?
      @paginator = Paginator.new(**options)
    end

    def self.paginator
      @paginator ||= nil
    end

    def self.paginate?
      !!@paginator if defined? @paginator
    end

    def self.query_factory
      Queries[result_type]
    end

    attr_accessor :access_control, :params, :request_body

    def initialize(access_control, params, env)
      @access_control = access_control
      @params         = params
      @queries        = {}
      @github         = {}
      @env            = env
      @request_body   = @env['rack.input'.freeze]
    end

    def query(type = result_type)
      @queries[type] ||= Queries[type].new(params, result_type, service: self)
    end

    def github(user = nil)
      @github[user] ||= GitHub.new(user)
    end

    def find(type = result_type, *args)
      not_found(true,  type) unless object = query(type).find(*args)
      not_found(false, type) unless access_control.visible? object
      object
    end

    def check_login_and_find(*args)
      raise LoginRequired unless access_control.full_access_or_logged_in?
      find(*args) or raise NotFound
    end

    def not_found(actually_not_found = false, type = nil)
      type, actually_not_found = actually_not_found, false if actually_not_found.is_a? Symbol
      error = actually_not_found ? EntityMissing : NotFound
      raise(error, type || result_type)
    end

    def run!
      not_implemented
    end

    def result_type
      self.class.result_type
    end

    def result(resource, **meta_data)
      return not_found unless resource
      meta_data[:type]           ||= meta_data[:result_type] || result_type
      meta_data[:status]         ||= 200
      meta_data[:access_control] ||= access_control
      meta_data[:resource]       ||= resource
      Result.new(access_control: access_control, type: meta_data[:type], resource: meta_data[:resource], **meta_data)
    end

    def head(**meta_data)
      meta_data[:access_control] ||= access_control
      meta_data[:type]           ||= result_type
      meta_data[:resource]       ||= nil
      Result::Head.new(access_control: access_control, type: result_type, resource: nil, **meta_data)
    end

    def deleted
      head(status: 204)
    end

    def no_content
      head(status: 204)
    end

    def run
      check_force_auth
      not_found unless result = run!
      result = paginate(result) if self.class.paginate?
      check_deprecated_params(result) if params['include']
      apply_warnings(result)
      result
    end

    def check_force_auth
      if access_control.force_auth?
        raise LoginRequired unless access_control.logged_in? || access_control.temp_access?
      end
    end

    def check_deprecated_params(result)
      case
      when params['include'].match(/repository.current_build/)
       result.deprecated_param('current_build', reason: "repository.last_started_build".freeze)
      when params['include'].match(/request.yaml_config/)
        result.deprecated_param('request.yaml_config', reason: "request.raw_configs".freeze)
      end
    end

    def warnings
      @warnings ||= []
    end

    def warn(*args, **info)
      warnings << args
    end

    def apply_warnings(result)
      warnings.each { |args| args.count > 1 ? result.warn(args[0], **args[1]) : result.warn(args[0]) }
    end

    def paginate(result)
      self.class.paginator.paginate(result,
        limit:          params['limit'.freeze],
        offset:         params['offset'.freeze],
        skip_count:     params['skip_count'.freeze] == 'true',
        access_control: access_control)
    end

    def params_for?(prefix)
      return true if params['@type'.freeze] == prefix
      return true if params[prefix].is_a? Hash
      params.keys.any? { |key| key.start_with? "#{prefix}." }
    end

    def accepted(**payload)
      payload[:resource_type] ||= result_type
      result(payload, status: 202, result_type: :accepted)
    end

    def rejected(payload)
      result(payload, status: 403, result_type: :error)
    end

    def migrated?(repo)
      Travis.config.org? && ["migrated", "migrating"].include?(repo.migration_status)
    end

    # TODO confirm message, link to docs?
    def repo_migrated(message = 'This repository has been migrated to travis-ci.com. Modifications to repositories, builds, and jobs are disabled on travis-ci.org. If you have any questions please contact us at support@travis-ci.com')
      result(Error.new(message, type: :repo_migrated), result_type: :error, status: 403)
    end

    def abuse_detected(message = 'Abuse detected. Restart disabled. If you think you have received this message in error, please contact support: support@travis-ci.com')
      rejected(Error.new(message, status: 403))
    end

    def insufficient_balance(message = 'Builds have been temporarily disabled for private repositories due to a insufficient credit balance')
      rejected(Error.new(message, status: 403))
    end

    def not_implemented
      raise NotImplemented
    end

    def private_repo_feature!(repository)
      raise PrivateRepoFeature unless access_control.enterprise? || repository.private?
    end

    def remote_vcs_repository
      @remote_vcs_repository ||= Travis::RemoteVCS::Repository.new
    end
  end
end
