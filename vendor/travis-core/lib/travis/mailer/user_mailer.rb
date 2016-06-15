require 'action_mailer'

class UserMailer < ActionMailer::Base
  ActionMailer::Base.append_view_path("#{File.dirname(__FILE__)}/views")

  layout 'contact_email'

  def welcome_email(user)
    @user = user
    mail(subject: "Welcome to Travis CI!", from: from, to: user.email) do |format|
      format.html
    end
  end

  def from
    Travis.config.email.from
  end
end
