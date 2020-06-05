module Travis::API::V3
  class Services::Build::BuildPrioritize < Service

    def run
      build = check_login_and_find(:build)
      build_priority = build.owner.build_priority?
      priority = build.priority?
      payload = { build: build, priority_status: priority, build_priority_permission: build_priority }
      result(payload, status: 200, result_type: :accepted)
    end
  end
end
