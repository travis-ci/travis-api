module Travis::API::V3
  class Queries::Build < Query
    params :id

    def find
      return Models::Build.find_by_id(id) if id
      raise WrongParams, 'missing build.id'.freeze
    end

    def cancel
      raise WrongParams, 'missing build.id'.freeze                         unless build.id
      payload = {
        build: { id: build.id }
      }

      perform_async(:build_cancellation, type: 'api'.freeze, credentials: { token: token }, payload: JSON.dump(payload))
      payload
    end
  end
end
