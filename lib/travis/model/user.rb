require 'gh'
require 'travis/model'
require 'travis/github/oauth'

class User < Travis::Model
  self.table_name = 'users'
  require 'travis/model/user/oauth'
  require 'travis/model/user/renaming'

  has_many :tokens, dependent: :destroy
  has_many :memberships, dependent: :destroy
  has_many :organizations, through: :memberships
  has_many :permissions, dependent: :destroy
  has_many :repositories, through: :permissions
  has_many :emails, dependent: :destroy
  has_one :owner_group, as: :owner
  has_many :custom_keys, as: :owner
  has_many :broadcasts, as: :recipient

  before_create :set_as_recent
  after_create :create_the_tokens
  before_save :track_previous_changes

  serialize :github_scopes

  serialize :github_oauth_token, Travis::Model::EncryptedColumn.new

  before_save do
    ensure_preferences
  end

  class << self
    def with_permissions(permissions)
      where(:permissions => permissions).includes(:permissions)
    end

    def find_or_create_for_oauth(payload)
      Oauth.find_or_create_by(payload)
    end

    def with_github_token
      where("github_oauth_token IS NOT NULL and github_oauth_token != ''")
    end

    def with_email(email_address)
      Email.where(email: email_address).first.try(:user)
    end
  end

  def token
    tokens.first.try(:token)
  end

  def to_json
    keys = %w/id login email name locale github_id gravatar_id is_syncing synced_at updated_at created_at/
    { 'user' => attributes.slice(*keys) }.to_json
  end

  def permission?(roles, options = {})
    roles, options = nil, roles if roles.is_a?(Hash)
    scope = permissions.where(options)
    scope = scope.by_roles(roles) if roles
    scope.any?
  end

  def first_sync?
    synced_at.nil?
  end

  def syncing?
    is_syncing?
  end

  def service_hook(options = {})
    service_hooks(options).first
  end

  def service_hooks(options = {})
    hooks = repositories
    unless options[:all]
      hooks = hooks.administrable
    end
    hooks = hooks.includes(:permissions).
              select('repositories.*, permissions.admin as admin, permissions.push as push')

    if options[:order] != 'none'
      hooks = hooks.order('owner_name, name')
    end

    # TODO remove owner_name/name once we're on api everywhere
    if options.key?(:id)
      hooks = hooks.where(options.slice(:id))
    elsif options.key?(:owner_name) || options.key?(:name)
      hooks = hooks.where(options.slice(:id, :owner_name, :name))
    end
    hooks
  end

  def organization_ids
    @organization_ids ||= memberships.map(&:organization_id)
  end

  def repository_ids
    @repository_ids ||= permissions.map(&:repository_id)
  end

  def recently_signed_up?
    !!@recently_signed_up
  end

  def profile_image_hash
    # TODO:
    #   If Github always sends valid gravatar_id in oauth payload (need to check that)
    #   then these fallbacks (email hash and zeros) are superfluous and can be removed.
    gravatar_id.presence || (email? && Digest::MD5.hexdigest(email)) || '0' * 32
  end

  def github_scopes
    github_oauth_token && read_attribute(:github_scopes) || []
  end

  # avatar_url calculation here is almost the same code that's used in
  # Travis::API::V3::Renderer::AvatarURL. While generally I don't
  # like repetition, it seems that copying it is the best choice in
  # this specific situation. We need to add this field as a bug fix
  # for travis-web, so I don't think that anyone else will be using
  # it, especially with V3 in place and plans to retire V2. We won't
  # likely need to do any maintenance here, because we plan to
  # switch to V3 for /user request soon. And lastly, with plans to
  # split V2 and V3 codebases I wouldn't like to share this code between V3 and
  # V2
  #
  GRAVATAR_URL = 'https://0.gravatar.com/avatar/%s'
  private_constant :GRAVATAR_URL

  def avatar_url
    if read_attribute(:avatar_url)
      read_attribute(:avatar_url)
    elsif gravatar_id
      GRAVATAR_URL % gravatar_id
    else
      GRAVATAR_URL % Digest::MD5.hexdigest(email)
    end
  end

  def subscribed?
    subscription.present? and subscription.active?
  end

  def subscription
    return @subscription if instance_variable_defined?(:@subscription)
    records = Subscription.where(owner_id: id, owner_type: "User")
    @subscription = records.where(status: 'subscribed').last || records.last
  end

  def _has
    self.respond_to?(field) and self.send(field).present?
  end

  def previous_changes
    @previous_changes ||= {}
  end

  def reload
    @previous_changes = nil
    super
  end

  def inspect
    github_oauth_token ? super.gsub(github_oauth_token, '[REDACTED]') : super
  end

  def create_the_tokens
    self.tokens.asset.create! unless self.tokens.asset.exists?
    self.tokens.rss.create! unless self.tokens.rss.exists?
    self.tokens.web.create! unless self.tokens.web.exists?
  end

  def github?
    vcs_type == 'GithubUser'
  end

  def ensure_preferences
    return if attributes['preferences'].nil?
    self.preferences = self['preferences'].is_a?(String) ? JSON.parse(self['preferences']) : self['preferences']
  end

  protected

    def track_previous_changes
      @previous_changes = changes
    end

    def set_as_recent
      @recently_signed_up = true
    end
end
