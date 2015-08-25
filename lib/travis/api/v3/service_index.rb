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

    def render(env)
      json_home?(env) ? json_home_response : json_response
    end

    def render_json
      resources = { }
      routes.resources.each do |resource|
        data = resources[resource.identifier] ||= { :@type => :resource, :actions => {} }
        if renderer = Renderer[resource.identifier, false] and renderer.respond_to? :representations
          data[:representations] = renderer.representations
        end
        resource.services.each do |(request_method, sub_route), service|
          list    = resources[resource.identifier][:actions][service] ||= []
          pattern = sub_route ? resource.route + sub_route : resource.route
          factory = Services[resource.identifier][service]
          pattern.to_templates.each do |template|
            params    = factory.params if request_method == 'GET'.freeze
            params  &&= params.reject { |p| p.start_with? ?@.freeze }
            template += "{?#{params.sort.join(?,)}}" if params and params.any?
            list << { :@type => :template, :request_method => request_method, :uri_template => prefix + template }
          end
        end
      end
      { :@type => :home, :@href => "#{prefix}/", :resources => resources }
    end

    def render_json_home
      relations = {}

      routes.resources.each do |resource|
        resource.services.each do |(request_method, sub_route), service|
          pattern  = sub_route ? resource.route + sub_route : resource.route
          relation = "http://schema.travis-ci.com/rel/#{resource.identifier}/#{service}"
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

      { resources: Hash[resources] }
    end

    def json_home?(env)
      env['HTTP_ACCEPT'.freeze] == 'application/json-home'.freeze
    end
  end
end
