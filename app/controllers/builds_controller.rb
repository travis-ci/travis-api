class BuildsController < ApplicationController
  def show
    @build = Build.find_by(id: params[:id])
    return redirect_to root_path, alert: "There is no build associated with that ID." if @build.nil?
  end
end
