class SearchController < ApplicationController
  def search
    unless params[:q].blank?
      query = params[:q].gsub(/([#{Regexp.escape('/')}])/, '\\\\\1')
      @results = Elasticsearch::Model.search(query, [User, Organization, Repository, Job, Build, Request]).records.to_a
    end
  end
end
