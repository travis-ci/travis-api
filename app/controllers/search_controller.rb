class SearchController < ApplicationController
  def search
    unless params[:q].blank?
      @results = Repository.search(params[:q])
    end
  end
end
