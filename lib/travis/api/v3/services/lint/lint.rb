module Travis::API::V3
  class Services::Lint::Lint < Service
    def run!
      lint
    end
  end
end
