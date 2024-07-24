module Travis::API::V3
  class Queries::User < Query
    setup_sidekiq(:user_sync, queue: :sync, class_name: "Travis::GithubSync::Worker")
    params :id, :login, :email, :github_id, :vcs_id, :vcs_type, :is_syncing

    def find
      return Models::User.find_by_id(id) if id
      return Models::User.find_by(vcs_id: github_id) || Models::User.find_by(github_id: github_id) if github_id
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

    def collaborator?(id)
      user = Models::User.find_by_id(id) if id
      return false unless user


      owners=[]
      user.organizations.each do |org|
        owners << {
          :id => org.id,
          :type => 'Organization'
        }
      end

      return owners.length > 0 if !!Travis.config.enterprise

      Models::Repository.where(id: user.shared_repositories_ids).uniq.pluck(:owner_id, :owner_type).each do |owner|
        owners << {
          :id => owner[0],
          :type =>owner[1]
        }
      end
      client = BillingClient.new(id)
      client.usage_stats(owners)
    end

    def sync(user)
      raise AlreadySyncing if user.is_syncing?
      if Travis::Features.user_active?(:use_vcs, user) || !user.github?
        Travis::RemoteVCS::User.new.sync(user_id: user.id)
        user.reload
      else
        perform_async(:user_sync, :sync_user, user_id: user.id)
        user.update_column(:is_syncing, true)
        user
      end
    end

    private

    def provider
      params['provider'] || 'github'
    end

  end
end
