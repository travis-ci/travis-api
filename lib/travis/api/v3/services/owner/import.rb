require 'travis/api/v3/models/import'

module Travis::API::V3
  class Services::Owner::Import < Service
    def result_type
      @result_type ||= super
    end

    def run!
      owner = check_login_and_find
      access_control.permissions(owner).import!

      Models::Import.new(owner, access_control.user).import!

      result(owner, status: 202, result_type: type_for(owner))
    rescue Models::Import::ImportDisabledError
      raise Error.new("Import is disabled for #{owner.login}. Please contact Travis CI support for more information", status: 403)
    rescue Models::Import::ImportRequestFailed
      raise Error.new('There was a problem with starting an import', status: 500)
    end

    private def type_for(owner)
      case owner
      when Models::User         then :user
      when Models::Organization then :organization
      end
    end
  end
end
