module Travis::API::V3
  class Services::Crons::Start < Service

    def run!
      started = []

      Models::Cron.all.each do |cron|
        if cron.next_enqueuing <= Time.now
          query.start(cron.branch)
          started.push cron
        end
      end

      started
    end

  end
end
