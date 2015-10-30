module Travis::API::V3
  class Queries::User < Query
    set_queue(:user_sync, :user_sync)
    params :id, :login, :email, :github_id, :is_syncing

    def find
      return Models::User.find_by_id(id) if id
      return Models::User.find_by_github_id(github_id) if github_id
      return Models::User.where('lower(login) = ?'.freeze, login.downcase).first if login
      return find_by_email(email) if email
      raise WrongParams, 'missing user.id or user.login'.freeze
    end

    def find_by_email(email)
      if email_model = Models::Email.find_by_email(email)
        email_model.user
      else
        User.find_by_email(email)
      end
    end

    def sync(user)
      raise AlreadySyncing if user.is_syncing?
      perform_async(:user_sync, user.id)
      user.update_column(:is_syncing, true)
      user
    end
  end
end
