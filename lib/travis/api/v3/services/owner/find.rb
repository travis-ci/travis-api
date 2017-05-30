module Travis::API::V3
  class Services::Owner::Find < Service
    def result_type
      @result_type ||= super
    end

    def run!
      owner        = find
      @result_type = type_for(owner)
      result owner
    end

    def type_for(owner)
      case owner
      when Models::User         then :user
      when Models::Organization then :organization
      end
    end
  end
end
