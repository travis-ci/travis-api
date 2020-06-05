module Travis::API::V3
  class Services::Build::BuildPrioritize < Service

    def run
      build = check_login_and_find(:build)
      build_priority = build.owner.build_priority?
      is_high_priority = build.priority_high?
      payload = { build: build, priority_status: is_high_priority, build_priority_permission: build_priority }
      result(payload, status: 200, result_type: :accepted)
    end
  end
end
