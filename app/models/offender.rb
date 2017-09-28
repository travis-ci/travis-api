module Offender
  LISTS = {trusted: "trusted account", offenders: "known offender", not_fishy: "not fishy"}

  extend self

  def abuse_ids
    Travis::DataStores.redis.smembers("abuse:offenders")
  end

  def user_ids
    abuse_ids.select { |s| s.start_with?('User:') }.map { |s| s.split(':').last.to_i }
  end

  def org_ids
    abuse_ids.select { |s| s.start_with?('Organization:') }.map { |s| s.split(':').last.to_i }
  end

  def users
    ::User.where(id: user_ids)
  end

  def organizations
    ::Organization.where(id: org_ids)
  end
end
