class SearchController < ApplicationController
  def search
    unless params[:q].blank?
      query = params[:q].gsub(/([#{Regexp.escape('/')}])/, '\\\\\1')
      payload = {
        from: 0, size: 20,
        query: {
          bool: {
            should: [
              { multi_match: {
                query: query,
                fuzziness: 2,
                fields: ['login^10', 'name', 'slug', 'email', 'emails']
              }}
            ]
          }
        }
      }
      @results = Elasticsearch::Model.search(payload, [User, Organization, Repository]).records.to_a
    end
  end
end
