module Travis::API::V3
  class Queries::InsightsPlugins < Query
    params :filter, :page, :limit, :active, :sort_by, :sort_direction, :key_hash, :plugin_id, :name, :plugin_type, :public_id,
      :private_key, :account_name, :app_key, :domain, :sub_plugin, :ids

    def all(user_id)
      insights_client(user_id).user_plugins(
        params['filter'],
        params['page'],
        params['active'],
        params['sort_by'],
        params['sort_direction']
      )
    end

    def create(user_id)
      insights_client(user_id).create_plugin(params.slice(*%w(key_hash name plugin_type public_id private_key account_name app_key domain sub_plugin)))
    end

    def toggle_active(user_id)
      insights_client(user_id).toggle_active_plugins(params['ids'])
    end

    def delete_many(user_id)
      insights_client(user_id).delete_many_plugins(params['ids'])
    end

    def generate_key(user_id)
      insights_client(user_id).generate_key(params['plugin_name'], params['plugin_type'])
    end

    def authenticate_key(user_id)
      insights_client(user_id).authenticate_key(params)
    end

    def template_plugin_tests(user_id)
      insights_client(user_id).template_plugin_tests(params['plugin_type'])
    end

    def get_scan_logs(user_id)
      insights_client(user_id).get_scan_logs(params['plugin_id'], params['last_id'])
    end

    private

    def insights_client(user_id)
      @_insights_client ||= InsightsClient.new(user_id)
    end
  end
end
