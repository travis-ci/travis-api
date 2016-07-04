class BroadcastsController < ApplicationController
  def index
    @active_broadcasts = Broadcast.active
    @recent_expired_broadcasts = Broadcast.recent_expired
  end
end
