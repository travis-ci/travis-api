module Travis::API::V3
  class Services::Executions::ForOwnerPerSender < Service
    params :from, :to
    result_type :executions_per_sender

    def run!
      raise MethodNotAllowed if Travis.config.org?
      raise LoginRequired unless access_control.logged_in?

      owner = query(:owner).find

      raise NotFound unless owner
      raise InsufficientAccess unless access_control.visible?(owner)

      results = query(:executions).for_owner(owner, access_control.user.id, 0, 0,
                                             params['from'], params['to'])
      result recuce_by_sender(results)
    end

    def recuce_by_sender(results) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      reduced = []
      results.each do |item|
        minutes_consumed = calculate_minutes(item.started_at, item.finished_at)
        obj = reduced.find { |one| one[:sender_id] == item.sender_id }
        if obj
          obj[:credits_consumed] += item.credits_consumed
          obj[:minutes_consumed] += minutes_consumed
        else
          sender = Travis::API::V3::Models::User.find(item.sender_id)
          reduced << {
            credits_consumed: item.credits_consumed,
            minutes_consumed: minutes_consumed,
            sender_id: item.sender_id,
            sender: Renderer.render_model(sender, mode: :standard, show_email: true)
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
