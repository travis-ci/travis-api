class RequestsController < ApplicationController
  def show
    @request = Request.find_by(id: params[:id])
    return redirect_to not_found_path, flash: {error: "There is no request associated with ID #{params[:id]}."} if @request.nil?
  end
end
