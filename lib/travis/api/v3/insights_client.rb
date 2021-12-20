# frozen_string_literal: true

module Travis::API::V3
  class InsightsClient
    class ConfigurationError < StandardError; end

    def initialize(user_id)
      @user_id = user_id
    end

    def user_notifications(filter, page, active, sort_by, sort_direction)
      query_string = query_string_from_params(
        value: filter,
        page: page || '1',
        active: active,
        order: sort_by,
        order_dir: sort_direction
      )
      response = connection.get("/user_notifications?#{query_string}")

      handle_errors_and_respond(response) do |body|
        notifications = body['data'].map do |notification|
          Travis::API::V3::Models::InsightsNotification.new(notification)
        end

        Travis::API::V3::Models::InsightsCollection.new(notifications, body.fetch('total_count'))
      end
    end

    def toggle_snooze_user_notifications(notification_ids)
      response = connection.put('/user_notifications/toggle_snooze', snooze_ids: notification_ids)

      handle_errors_and_respond(response)
    end

    def user_plugins(filter, page, active, sort_by, sort_direction)
      query_string = query_string_from_params(
        value: filter,
        page: page || '1',
        active: active,
        order: sort_by,
        order_dir: sort_direction
      )
      response = connection.get("/user_plugins?#{query_string}")

      handle_errors_and_respond(response) do |body|
        plugins = body['data'].map do |plugin|
          Travis::API::V3::Models::InsightsPlugin.new(plugin)
        end

        Travis::API::V3::Models::InsightsCollection.new(plugins, body.fetch('total_count'))
      end
    end

    def create_plugin(params)
      response = connection.post("/user_plugins", user_plugin: params)
      handle_errors_and_respond(response) do |body|
        Travis::API::V3::Models::InsightsPlugin.new(body['plugin'])
      end
    end

    def toggle_active_plugins(plugin_ids)
      response = connection.put('/user_plugins/toggle_active', toggle_ids: plugin_ids)

      handle_errors_and_respond(response) do |body|
        Travis::API::V3::Models::InsightsCollection.new([], 0)
      end
    end

    def delete_many_plugins(plugin_ids)
      response = connection.delete('/user_plugins/delete_many', delete_ids: plugin_ids)

      handle_errors_and_respond(response) do |body|
        Travis::API::V3::Models::InsightsCollection.new([], 0)
      end
    end

    def generate_key(plugin_name, plugin_type)
      response = connection.get('/user_plugins/generate_key', name: plugin_name, plugin_type: plugin_type)

      handle_errors_and_respond(response) do |body|
        body
      end
    end

    def authenticate_key(params)
      response = connection.post('/user_plugins/authenticate_key', params)

      handle_errors_and_respond(response) do |body|
        body
      end
    end

    def template_plugin_tests(plugin_type)
      response = connection.get("/user_plugins/#{plugin_type}/template_plugin_tests")

      handle_errors_and_respond(response) do |body|
        body
      end
    end

    def get_scan_logs(plugin_id, last_id)
      params = last_id ? { last: last_id, poll: true } : {}
      response = connection.get("/user_plugins/#{plugin_id}/get_scan_logs", params)

      handle_errors_and_respond(response) do |body|
        body
      end
    end

    def probes(filter, page, active, sort_by, sort_direction)
      query_string = query_string_from_params(
        value: filter,
        page: page || '1',
        active: active,
        order: sort_by,
        order_dir: sort_direction
      )
      response = connection.get("/probes?#{query_string}")

      handle_errors_and_respond(response) do |body|
        probes = body['data'].map do |probe|
          Travis::API::V3::Models::InsightsProbe.new(probe)
        end

        Travis::API::V3::Models::InsightsCollection.new(probes, body.fetch('total_count'))
      end
    end

    def create_probe(params)
      response = connection.post("/probes", test_template: params)
      handle_errors_and_respond(response) do |body|
        Travis::API::V3::Models::InsightsProbe.new(body)
      end
    end

    def update_probe(params)
      response = connection.patch("/probes/#{params['probe_id']}", params)
      handle_errors_and_respond(response) do |body|
        Travis::API::V3::Models::InsightsProbe.new(body)
      end
    end

    def toggle_active_probes(probe_ids)
      response = connection.put('/probes/toggle_active', toggle_ids: probe_ids)

      handle_errors_and_respond(response) do |body|
        Travis::API::V3::Models::InsightsCollection.new([], 0)
      end
    end

    def delete_many_probes(probe_ids)
      response = connection.delete('/probes/delete_many', delete_ids: probe_ids)

      handle_errors_and_respond(response) do |body|
        Travis::API::V3::Models::InsightsCollection.new([], 0)
      end
    end

    def sandbox_plugins(plugin_type)
      response = connection.post('/sandbox/plugins', plugin_type: plugin_type)

      handle_errors_and_respond(response) do |body|
        body
      end
    end

    def sandbox_plugin_data(plugin_id)
      response = connection.post('/sandbox/plugin_data', plugin_id: plugin_id)

      handle_errors_and_respond(response) do |body|
        body
      end
    end

    def sandbox_run_query(plugin_id, query)
      response = connection.post('/sandbox/run_query', plugin_id: plugin_id, query: query)

      handle_errors_and_respond(response) do |body|
        body
      end
    end

    def public_key
      response = connection.get('/api/v1/public_keys/latest.json')

      handle_errors_and_respond(response) do |body|
        Travis::API::V3::Models::InsightsPublicKey.new(body)
      end
    end

    def search_tags
      response = connection.get('/tags')

      handle_errors_and_respond(response) do |body|
        tags = body.map do |tag|
          Travis::API::V3::Models::InsightsTag.new(tag)
        end
      end
    end

    private

    def handle_errors_and_respond(response)
      case response.status
      when 200, 201
        yield(response.body) if block_given?
      when 202
        true
      when 204
        true
      when 400
        raise Travis::API::V3::ClientError, response.body.fetch('error', '')
      when 403
        raise Travis::API::V3::InsufficientAccess, response.body['rejection_code']
      when 404
        raise Travis::API::V3::NotFound, response.body.fetch('error', '')
      when 422
        raise Travis::API::V3::UnprocessableEntity, response.body.fetch('error', '')
      else
        raise Travis::API::V3::ServerError, 'Insights API failed'
      end
    end

    def connection(timeout: 10)
      @connection ||= Faraday.new(url: insights_api_url, ssl: { ca_path: '/usr/lib/ssl/certs' }) do |conn|
        conn.headers[:Authorization] = "Token token=\"#{insights_auth_token}\""
        conn.headers['X-Travis-User-Id'] = @user_id.to_s
        conn.headers['Content-Type'] = 'application/json'
        conn.request :json
        conn.response :json
        conn.options[:open_timeout] = timeout
        conn.options[:timeout] = timeout
        conn.use OpenCensus::Trace::Integrations::FaradayMiddleware if Travis::Api::App::Middleware::OpenCensus.enabled?
        conn.adapter :net_http
      end
    end

    def insights_api_url
      Travis.config.new_insights.insights_api_url || raise(ConfigurationError, 'No Insights API URL configured!')
    end

    def insights_auth_token
      Travis.config.new_insights.insights_auth_token || raise(ConfigurationError, 'No Insights Auth Token configured!')
    end

    def query_string_from_params(params)
      params.delete_if { |_, v| v.nil? || v.empty? }.to_query
    end
  end
end
