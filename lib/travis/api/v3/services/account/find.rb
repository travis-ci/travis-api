module Travis::API::V3
  class Services::Account::Find < Service
    def result_type
      @result_type ||= super
    end

    def run!
      account      = find
      @result_type = type_for(account)
      account
    end

    def type_for(account)
      case account
      when Models::User         then :user
      when Models::Organization then :organization
      end
    end
  end
end
