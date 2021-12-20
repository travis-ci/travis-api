module Travis::API::V3
  class Services::InsightsTags::SearchTags < Service
    result_type :insights_tags

    def run!
      raise LoginRequired unless access_control.full_access_or_logged_in?
      result query(:insights_tags).search_tags(access_control.user.id)
    end
  end
end
