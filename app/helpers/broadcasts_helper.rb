module BroadcastsHelper
  def expire_broadcast_btn_text(broadcast)
    if broadcast.inactive?
      "Expired"
    elsif broadcast.explicit_expired?
      "Display"
    else
      "Hide"
    end
  end
end
