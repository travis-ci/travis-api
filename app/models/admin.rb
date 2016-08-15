class Admin
  def self.logins
    Travis::Config.load.admins
  end

  def self.users
    User.where(login: logins).order(:name)
  end
end
