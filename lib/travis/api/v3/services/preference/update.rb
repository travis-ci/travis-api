module Travis::API::V3
  class Services::Preference::Update < Service
    params :value, prefix: :preference

    def run!
    end
  end
end
