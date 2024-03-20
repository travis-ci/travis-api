require 'gh'
require 'travis/model'

class Organization < Travis::Model
  self.table_name = 'organizations'
  has_many :memberships
  has_many :users, :through => :memberships
  has_many :repositories, :as => :owner
  has_one :owner_group, as: :owner
  has_many :custom_keys, as: :owner
  has_many :broadcasts, as: :recipient

  after_initialize do
    ensure_preferences
  end

  before_save do
    ensure_preferences
  end

  before_save do
    ensure_preferences
  end

  def education?
    Travis::Features.owner_active?(:educational_org, self)
  end
  alias education education?

  def subscribed?
    subscription.present? and subscription.active?
  end

  def subscription
    return @subscription if instance_variable_defined?(:@subscription)
    records = Subscription.where(owner_id: id, owner_type: "Organization")
    @subscription = records.where(status: 'subscribed').last || records.last
  end

  def ensure_preferences
    return if attributes['preferences'].nil?
    self.preferences = self['preferences'].is_a?(String) ? JSON.parse(self['preferences']) : self['preferences']
  end
end

