class User < ApplicationRecord
  include JobBoost
  include PreferencesHelper

  has_many :emails
  has_many :memberships
  has_many :abuses, foreign_key: :owner_id, class_name: 'Abuse'
  has_many :permissions
  has_many :organizations,          through: :memberships
  has_many :repositories,           as:      :owner
  has_many :permitted_repositories, through: :permissions, source: :repository
  has_many :broadcasts,             as:      :recipient
  has_many :trials,                 as:      :owner
  has_one  :installation,           as:      :owner

  serialize :github_oauth_token, Travis::EncryptedColumn.new

  scope :active, -> { where('suspended = false AND github_oauth_token IS NOT NULL') }
  scope :inactive, -> { where('suspended = false AND github_oauth_token IS NULL') }
  scope :suspended, -> { where(suspended: true) }

  alias_attribute :vcs_token, :github_token
  alias_attribute :vcs_oauth_token, :github_oauth_token
  alias_attribute :vcs_scopes, :github_scopes
  alias_attribute :vcs_language, :github_language

  def has_2fa?
    Travis::DataStores.redis.get("admin-v2:otp:#{login}")
  end

  def travis_admin?
    admins = travis_config.admins
    admins.respond_to?(:include?) && admins.include?(login)
  end

  def latest_trial
    trials.underway.order(created_at: :desc).first
  end

  def subscription
    v2_service = Services::Billing::V2Subscription.new(id.to_s, 'User')
    v2_subscription = v2_service.subscription
    v2_subscription || Subscription.find_by(owner_id: id)
  end

  def enterprise_status
    case
    when suspended?
      time = suspended_at.in_time_zone
      "Suspended on %s at %s" % [time.strftime('%-d %B %Y'), time.strftime('%R')]
    when !suspended? && !github_oauth_token
      'Inactive'
    else
      'Active'
    end
  end
end
