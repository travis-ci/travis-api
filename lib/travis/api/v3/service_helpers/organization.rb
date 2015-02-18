module Travis::API::V3
  module ServiceHelpers::Organization
    def organization
      @organization ||= find_organization
    end

    def find_organization
      not_found(true, :organization)  unless org = query(:organization).find
      not_found(false, :organization) unless access_control.visible? org
      org
    end
  end
end
