module Travis::API::V3
  class Queries::User < Query
    params :id, :login, :email

    def find
      return Models::User.find_by_id(id) if id
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
  end
end
