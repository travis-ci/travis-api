module Travis
  module Api
    module V2
      module Http
        class Accounts
          include Formats

          attr_reader :accounts, :options

          def initialize(accounts, options = {})
            @accounts = accounts
            @options = options
          end

          def data
            {
              :accounts => accounts.map { |account| account_data(account) }
            }
          end

          private

            def account_data(account)
              {
                'id' => account.id,
                'name' => account.name,
                'login' => account.login,
                'type' => account.type.underscore,
                'repos_count' => account.repos_count
              }
            end
        end
      end
    end
  end
end


