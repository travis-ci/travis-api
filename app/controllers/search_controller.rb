class SearchController < ApplicationController
  def search
    unless params[:q].blank?
      @results = User.fuzzy_search(login: params[:q])
    end
  end
end
