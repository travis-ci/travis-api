require 'travis/services/base'
require 'travis/notification'

module Travis
  module Services
    class NextBuildNumber < Base
      extend Travis::Instrumentation

      register :next_build_number

      def run
        number = repository.next_build_number
        if number.nil?
          number = repository.builds.maximum('number::int4').to_i + 1
          repository.next_build_number = number + 1
        else
          repository.next_build_number += 1
        end
        repository.save!(validate: false)
        number
      end
      instrument :run

      def repository
        @repository ||= Repository.find(params[:repository_id])
      end

      class Instrument < Notification::Instrument
        def run_completed
          params = target.params
          publish(
            msg: "for repository_id=#{params[:repository_id]}",
            repository_id: params[:repository_id]
          )
        end
      end
      Instrument.attach_to(self)
    end
  end
end
