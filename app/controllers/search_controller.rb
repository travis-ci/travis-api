class SearchController < ApplicationController
  def search
    unless params[:q].blank?
      @results = Elasticsearch::Model.search(params[:q], [User, Organization, Repository, Job, Build, Request]).records.to_a
    end
  end
end
