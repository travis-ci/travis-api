class User < ApplicationRecord
  include JobBoost

  has_many :emails
  has_many :memberships
  has_many :permissions
  has_many :organizations,          through: :memberships
  has_many :repositories,           as:      :owner
  has_many :permitted_repositories, through: :permissions, source: :repository
  has_many :broadcasts,             as:      :recipient
  has_one  :subscription,           as:      :owner

  def has_2fa?
    Travis::DataStores.redis.get("admin-v2:otp:#{login}")
  end

  def travis_admin?
    travis_config = Travis::Config.load
    admins = travis_config.admins
    admins.respond_to?(:include?) && admins.include?(login)
  end
end
