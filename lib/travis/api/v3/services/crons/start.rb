module Travis::API::V3
  class Services::Crons::Start < Service

    def run!
      started = []

      Models::Cron.all.each do |cron|
        if cron.next_build_time <= Time.now
          cron.start
          started.push cron
        end
      end

      started
    end

  end
end
