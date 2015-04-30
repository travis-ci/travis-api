module Travis::API::V3
  class Queries::Request < Query
    params :message, :branch, :config, prefix: :request

    def schedule(repository, user)
      raise ServerError, 'repository does not have a github_id'.freeze unless repository.github_id
      raise WrongParams, 'missing user'.freeze                         unless user and user.id

      payload = {
        repository: { id: repository.github_id, owner_name: repository.owner_name, name: repository.name },
        user:       { id: user.id },
        message:    message,
        branch:     branch || repository.default_branch_name,
        config:     config || {}
      }

      perform_async(:build_request, type: 'api'.freeze, credentials: {}, payload: JSON.dump(payload))
      payload
    end
  end
end
