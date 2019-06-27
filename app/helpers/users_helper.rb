module UsersHelper
  def become_url(user)
    "#{travis_config.become_endpoint}/#{user.login}"
  end

  def hidden(user, field)
    truncate(user.public_send(field).to_s.gsub(/./, ?*), 30)
  end

  def abuse_name(abuse)
    abuse.level == Abuse::LEVEL_OFFENDER ? 'offensive' : 'fishy'
  end

  private

  def truncate(string, max)
    string.length > max ? (string[0...max]).to_s : string
  end

  def travis_config
    Rails.configuration.travis_config
  end
end
