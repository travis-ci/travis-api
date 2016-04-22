module Travis::API::V3
  class Services::Crons::Start < Service

    def run!
      query.start_all()
    end

  end
end
