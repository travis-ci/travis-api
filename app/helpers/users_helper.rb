module UsersHelper
  def become_url(user)
    "#{travis_config.become_endpoint}/id/#{user.id}"
  end

  def hidden(user, field)
    truncate(user.public_send(field).to_s.gsub(/./, '*'), 30)
  end

  def vcs_user_profile_url(user)
    Travis::Providers.get(user.vcs_type).new(user).profile_link
  end

  def manage_repo_link_url(user)
    Travis::Providers.get(user.vcs_type).new(user).manage_repo_link
  end

  private

  def truncate(string, max)
    string.length > max ? (string[0...max]).to_s : string
  end

  def travis_config
    Rails.configuration.travis_config
  end
end
