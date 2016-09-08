class EventLogsController < ApplicationController
  def index
    @logs = Travis::DataStores.redis.lrange("admin-v2:logs", 0, -1)
  end
end
