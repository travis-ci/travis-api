class BroadcastsController < ApplicationController
  def index
    @active_broadcasts = Broadcast.active
    @recent_expired_broadcasts = Broadcast.recent_expired
  end

  def create
    @broadcast = Broadcast.new(broadcast_params)
    @recipient = @broadcast.recipient

    if @broadcast.save
      flash[:notice] = "Broadcast created."
    else
      flash[:error] = "Could not create broadcast."
    end

    redirect_to_broadcast_view(@recipient)
  end

  def expire
    @broadcast = Broadcast.find(params[:id])

    if params['broadcast'] && params['broadcast']['recipient_type']
      @recipient = Object.const_get(params['broadcast']['recipient_type']).find(params['broadcast']['recipient_id'])
    else
      @recipient = 'everybody'
    end

    @broadcast.toggle(:expired)
    @broadcast.save

    redirect_to_broadcast_view(@recipient)
  end

  private
    def broadcast_params
      params.require(:broadcast).permit(:recipient_type, :recipient_id, :message, :category)
    end

    def redirect_to_broadcast_view(recipient)
      case recipient
      when User
        redirect_to user_path(recipient, anchor: "broadcast")
      when Organization
        redirect_to organization_path(recipient, anchor: "broadcast")
      when Repository
        redirect_to repository_path(recipient, anchor: "broadcast")
      else
        redirect_to broadcast_path
      end
    end
end
