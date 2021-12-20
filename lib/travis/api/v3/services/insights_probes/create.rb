module Travis::API::V3
  class Services::InsightsProbes::Create < Service
    params :test_template_id, :test, :plugin_type,
      :notification, :description, :description_link, :type, :labels, :tag_list, :severity
    result_type :insights_probe

    def run!
      raise LoginRequired unless access_control.full_access_or_logged_in?
      result query(:insights_probes).create(access_control.user.id)
    end
  end
end
