class Offender
  include ActiveModel::Model

  def self.logins
    Travis::DataStores.redis.smembers("abuse:offenders")
  end

  def self.users
    User.where(login: logins)
  end

  def self.organizations
    Organization.where(login: logins)
  end
end
