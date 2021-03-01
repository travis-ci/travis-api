module Travis::API::V3
  class Queries::User < Query
    params :id, :login, :email, :vcs_id, :vcs_type, :is_syncing

    def find
      return Models::User.find_by_id(id) if id
      return Models::User.find_by(vcs_id: vcs_id) if vcs_id
      return Models::User.where(
        'lower(login) = ? and lower(vcs_type) = ?'.freeze,
        login.downcase,
        provider.downcase + 'user'
      ).order("id DESC").first if login
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

      Travis::RemoteVCS::User.new.sync(user_id: user.id)
      user.reload
    end

    private

    def provider
      params['provider'] || 'github'
    end

  end
end
