class RequestsController < ApplicationController
  def show
    @request = Request.find_by(id: params[:id])
    return redirect_to root_path, alert: "There is no request associated with that ID." if @request.nil?
  end
end
