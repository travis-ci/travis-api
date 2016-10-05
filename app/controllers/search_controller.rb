class SearchController < ApplicationController
  def search
    unless params[:q].blank?
      query = params[:q].gsub(/([#{Regexp.escape('/')}])/, '\\\\\1')
      # TO DO: query should be further modified to extract ids from urls, also doesn't search for build/job slugs

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
      elasticsearch = Elasticsearch::Model.search(payload, [User, Organization, Repository]).records.to_a

      build   = Build.find_by(id: query)
      job     = Job.find_by(id: query)
      request = Request.find_by(id: query)

      @results = elasticsearch.unshift(build, job, request).compact
    end
  end
end
