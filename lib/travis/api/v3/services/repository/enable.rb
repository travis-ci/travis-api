module Travis::API::V3
  class Services::Repository::Enable < Services::Repository::Disable
    def run!
      super(true)
    end
  end
end
