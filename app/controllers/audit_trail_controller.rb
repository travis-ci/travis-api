class AuditTrailController < ApplicationController
  def index
    @logs = redis.lrange("admin-v2:logs", 0, -1).map { |log| fmt(log) }
  end

  private

  def fmt(log)
    log.starts_with?('<') ? { 'message' => log } : Logfmt.parse(log)
  end

  def redis
    Travis::DataStores.redis
  end
end
