class SearchController < ApplicationController
  def search
    unless params[:q].blank?
      redirect_to help_path if params[:q] == 'help'

      @results = Services::Search.new(params[:q]).call
      redirect_to(@results.first) if @results.size == 1
    end
  end

  def help
  end
end
