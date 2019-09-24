module Travis::API::V3
  class Queries::User < Query
    setup_sidekiq(:user_sync, queue: :sync, class_name: "Travis::GithubSync::Worker")
    params :id, :login, :email, :github_id, :vcs_id, :is_syncing

    def find
      return Models::User.find_by_id(id) if id
      return Models::User.find_by_github_id(github_id) if github_id
      return Models::User.where('lower(login) = ?'.freeze, login.downcase).order("id DESC").first if login
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
      perform_async(:user_sync, :sync_user, user_id: user.id)
      user.update_column(:is_syncing, true)
      user
    end
  end
end
