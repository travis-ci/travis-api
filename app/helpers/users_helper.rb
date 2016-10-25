module UsersHelper
  def become_url(user)
    "#{Travis::Config.load.become_endpoint}/#{user.login}"
  end

  def hidden(user, field)
    truncate(user.public_send(field).to_s.gsub(/./, ?*), 30)
  end

  private

  def truncate(string, max)
    string.length > max ? "#{string[0...max]}" : string
  end
end
