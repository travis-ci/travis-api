module Travis::API::V3
  class Queries::UserBuilds < Query
    params :id

    def find
      return [] unless params["user.id"]

      if user_id = Models::User.find_by_id(params["user.id"].to_i).id
        V3::Models::Build.where(
          sender_id: user_id,
          sender_type: 'User'
        )
      else
        []
      end
    end
  end
end
