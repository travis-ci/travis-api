module Travis::API::V3
  class Queries::Requests < Query
    def find(repository)
      if params.include?('branch')
        branch = repository.branches.where(name: params['branch']).first
        return repository.requests.none unless branch
      end
      relation = repository.requests.includes(:commit)
      relation = relation.includes(:yaml_config) if includes?('request.yaml_config')
      relation = relation.where('created_at >= ?'.freeze, params['from']) if params.include?('from')
      relation = relation.where('created_at <= ?'.freeze, params['to']) if params.include?('to')
      relation = relation.where(result: params['result']) if params.include?('result')
      relation = relation.where(state: params['state']) if params.include?('state')
      relation = relation.where(branch_id: branch.id) if branch
      relation.order(id: :desc)
    end

    def count(repository, time_frame)
      find(repository).
        where(event_type: 'api'.freeze).
        where('created_at > ?'.freeze, time_frame.ago).count
    end
  end
end
