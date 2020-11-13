module Travis::API::V3
  class Services::Executions::ForOwnerPerRepo < Service
    params :from, :to
    result_type :executions_per_repo

    def run!
      raise MethodNotAllowed if Travis.config.org?
      raise LoginRequired unless access_control.logged_in?

      owner = query(:owner).find

      raise NotFound unless owner
      raise InsufficientAccess unless access_control.visible?(owner)

      results = query(:executions).for_owner(owner, access_control.user.id, 0, 0,
                                             params['from'], params['to'])
      result recuce_by_repo(results)
    end

    def recuce_by_repo(results) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      reduced = []
      results.each do |item|
        minutes_consumed = calculate_minutes(item.started_at, item.finished_at)
        obj = reduced.find { |one| one[:repository_id] == item.repository_id && one[:os] == item.os }
        if obj
          obj[:credits_consumed] += item.credits_consumed
          obj[:minutes_consumed] += minutes_consumed
        else
          repo = Travis::API::V3::Models::Repository.find(item.repository_id)
          reduced << {
            repository_id: item.repository_id,
            os: item.os,
            credits_consumed: item.credits_consumed,
            minutes_consumed: minutes_consumed,
            repository: Renderer.render_model(repo, mode: :standard)
          }
        end
      end
      reduced
    end

    def calculate_minutes(start, finish)
      return 0 if start.to_s.empty? || finish.to_s.empty?

      ((Time.parse(finish.to_s) - Time.parse(start.to_s)) / 60.to_f).ceil
    end
  end
end
