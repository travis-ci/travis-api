class SearchController < ApplicationController
  def search
    unless params[:q].blank?
      @results = Services::Search.new(params[:q]).call
      redirect_to(@results.first) if @results.size == 1
    end
  end
end
