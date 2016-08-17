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

    redirect_to_broadcast_view
  end

  def update
    @broadcast = Broadcast.find_by(id: params[:id])

    @broadcast.toggle(:expired)
    @broadcast.save

    redirect_to_broadcast_view
  end

  private
    def broadcast_params
      params.require(:broadcast).permit(:recipient_type, :recipient_id, :message, :category)
    end

    def redirect_to_broadcast_view
      if params[:broadcast] && broadcast_params[:recipient_type]
        recipient_class = Object.const_get(broadcast_params[:recipient_type])
        recipient = recipient_class.find_by(id: broadcast_params[:recipient_id])
      end

      return redirect_to broadcasts_path unless recipient
      redirect_to :controller => recipient_class.table_name, :action => 'show', :id => recipient, anchor: 'broadcast'
    end
end
