module UsersHelper
  def hidden(user, field)
    user.public_send(field).to_s.gsub(/./, ?*)
  end
end
