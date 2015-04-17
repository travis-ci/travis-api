module Travis::API::V3
  class Queries::Accounts < Query
    def for_member(user)
      organizations = Queries[:organizations].new(params, main_type).for_member(user)
      accounts(user, organizations)
    end

    private

    def accounts(*list)
      list.flatten.map { |entry| account(entry) }
    end

    def account(entry)
      case entry
      when Models::User, Models::Organization then Models::Account.new(entry)
      when Models::Account, nil               then entry
      else raise ArgumentError, 'cannot convert %p into an account'.freeze % [entry]
      end
    end
  end
end
