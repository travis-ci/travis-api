module Travis::API::V3
  class ServiceIndex
    ALLOW_POST = ['application/json', 'application/x-www-form-urlencoded', 'multipart/form-data']
    @index_cache = {}

    def self.for(env, routes)
      access_factory = AccessControl.new(env).class
      prefix         = env['SCRIPT_NAME'.freeze]
      @index_cache[[access_factory, routes, prefix]] ||= new(access_factory, routes, prefix)
    end

    attr_reader :access_factory, :routes, :json_home_response, :json_response, :prefix

    def initialize(access_factory, routes, prefix)
      @prefix                  = prefix || ''
      @access_factory, @routes = access_factory, routes
      @json_response           = V3.response(render_json,      content_type: 'application/json'.freeze)
      @json_home_response      = V3.response(render_json_home, content_type: 'application/json-home'.freeze)
    end

    def config
      # TODO: move this somewhere else?
      pusher_config = (Travis.config.pusher_ws || Travis.config.pusher.to_h || {}).to_hash.slice(:scheme, :host, :port, :path, :key, :secure, :private)
      {
        host:   Travis.config.client_domain || Travis.config.host,
        github: V3::GitHub.client_config,
        pusher: pusher_config
      }
    end

    def all_resources
      @all_resources ||= begin
        home_actions = {
          find: [{
            :@type          => :template,
            :request_method => :GET,
            :uri_template   => prefix + ?/
          }]
        }

        all = routes.resources + [
          Routes::Resource.new(:broadcast), # dummy as there are only broadcasts routes right now
          Routes::Resource.new(:commit),    # dummy as commits can only be embedded
          Routes::Resource.new(:message),   # dummy as there is only a messages route right now
          Routes::Resource.new(:request),   # dummy as there are only requests routes right now
          Routes::Resource.new(:stage),     # dummy as there is no stage endpoint at the moment
          Routes::Resource.new(:error),
          Routes::Resource.new(:home,     attributes: [:config, :errors, :resources], actions: home_actions),
          Routes::Resource.new(:resource, attributes: [:actions, :attributes, :representations, :access_rights]),
          Routes::Resource.new(:template, attributes: [:request_method, :uri_template])
        ]

        all.sort_by(&:display_identifier)
      end
    end

    def error_payload(error)
      attributes      = []
      default_message = error.default_message

      if default_message.is_a? Symbol
        default_message = error.template % default_message
        attributes << :resource_type
      end

      if error == InsufficientAccess
        attributes << :resource_type
        attributes << :permission
      end

      { status: error.status, default_message: default_message, additional_attributes: attributes.uniq.sort }
    end

    def errors
      errors = V3.constants.map { |c| V3.const_get(c) }.select { |c| c < V3::Error }
      errors.map { |e| [e.type, error_payload(e)] }.sort_by(&:first).to_h
    end

    def render(env)
      json_home?(env) ? json_home_response : json_response
    end

    def render_json
      resources = { }
      all_resources.each do |resource|
        next if resource.meta_data[:hidden]
        data = resources[resource.display_identifier] ||= { :@type => :resource, :actions => {} }
        data.merge! resource.meta_data

        if renderer = Renderer[resource.identifier, false]

          data[:attributes] = renderer.available_attributes if renderer.respond_to? :available_attributes

          if renderer.respond_to? :representations
            representations = renderer.representations
            if renderer.respond_to? :hidden_representations
              representations = representations.reject { |k| renderer.hidden_representations.include? k }
            end
            data[:representations] = representations
          end
        end

        if permissions           = Permissions[resource.display_identifier, false]
          data[:permissions]     = permissions.access_rights.keys
        end

        resource.services.each do |(request_method, sub_route), service|
          next if resource.service_hidden?(service)
          list    = resources[resource.display_identifier][:actions][service] ||= []
          pattern = sub_route ? resource.route + sub_route : resource.route
          factory = Services[resource.identifier][service]
          query   = Queries[resource.display_identifier, false]

          if factory.params and factory.params.include? "sort_by".freeze
            if query and query.sortable?
              resources[resource.display_identifier][:sortable_by]  = query.sort_by.keys - query.experimental_sortable_by
              resources[resource.display_identifier][:default_sort] = query.default_sort unless query.default_sort.empty?
            end
          end

          pattern.to_templates.each do |template|
            params    = factory.params if request_method == 'GET'.freeze
            params  &&= params.reject { |p| p.start_with?(?@.freeze) }
            params  &&= params.reject { |p| p == 'skip_count'.freeze || p == 'representation'.freeze }

            if query
              params &&= params.reject { |p| query.get_experimental_params.include?(p) }
            end

            template += "{?#{params.sort.join(?,)}}" if params and params.any?
            action    = {
              :@type => :template,
              :request_method => request_method,
              :uri_template => prefix + template
            }
            action[:accepted_params] = factory.accepted_params.uniq if ['POST'.freeze, 'PATCH'.freeze].include? request_method
            list << action
          end

        end
      end

      set_to_a({
        :@type     => :home,
        :@href     => "#{prefix}/",
        :config    => config,
        :errors    => errors,
        :resources => resources
      })
    end

    def render_json_home
      relations = {}

      all_resources.each do |resource|
        resource.services.each do |(request_method, sub_route), service|
          pattern  = sub_route ? resource.route + sub_route : resource.route
          relation = "http://schema.travis-ci.com/rel/#{resource.display_identifier}/#{service}"
          pattern.to_templates.each do |template|
            relations[relation]           ||= {}
            relations[relation][template] ||= { allow: [], vars: template.scan(/{\+?([^}]+)}/).flatten }
            relations[relation][template][:allow] << request_method
          end
        end
      end

      nested_relations = {}
      relations.delete_if do |relation, request_map|
        next if request_map.size < 2
        common_vars    = request_map.values.map { |e| e[:vars] }.inject(:&)
        request_map.each do |template, payload|
          special_vars             = payload[:vars] - common_vars
          schema                   = special_vars.any? ? "#{relation}/by_#{special_vars.join(?_)}" : relation
          nested_relations[schema] = { template => payload }
        end
      end
      relations.merge! nested_relations

      resources = relations.map do |relation, payload|
        template, payload        = payload.first
        hints                    = { 'allow' => payload[:allow] }
        hints['accept-post']     = ALLOW_POST if payload[:allow].include? 'POST'
        hints['accept-patch']    = ALLOW_POST if payload[:allow].include? 'PATCH'
        hints['accept-put']      = ALLOW_POST if payload[:allow].include? 'PUT'
        hints['representations'] = ['application/json', 'application/vnd.travis-ci.3+json']
        [relation, {
          'href-template' => prefix + template,
          'href-vars'     => Hash[payload[:vars].map { |var| [var, "http://schema.travis-ci.com/param/#{var}"] }],
          'hints'         => hints
        }]
      end

      set_to_a({ resources: Hash[resources] })
    end

    def json_home?(env)
      env['HTTP_ACCEPT'.freeze] == 'application/json-home'.freeze
    end

    def set_to_a(data)
      case data
      when Hash
        data.map { |k,v| [set_to_a(k), set_to_a(v)] }.to_h
      when Array
        data.map { |v| set_to_a(v) }
      when Set
        data.map { |v| set_to_a(v) }.to_a
      else
        data
      end
    end
  end
end
