require 'gh'
require 'travis/model'

class Organization < Travis::Model
  has_many :memberships
  has_many :users, :through => :memberships
  has_many :repositories, :as => :owner

  def vcs_id
    read_attribute(:vcs_id) || github_id
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
end

