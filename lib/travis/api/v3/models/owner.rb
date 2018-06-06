module Travis::API::V3
  module Models::Owner
    private

    def fetch_owner(attributes)
      owner_class = case attributes.fetch('type')
                    when 'User'
                      Models::User
                    when 'Organization'
                      Models::Organization
                    end
      owner_class.find(attributes.fetch('id'))
    end
  end
end
