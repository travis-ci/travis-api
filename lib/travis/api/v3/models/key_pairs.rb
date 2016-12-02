require_relative './json_sync'

module Travis::API::V3
  class Models::KeyPairs < Travis::Settings::Collection
    include Models::JsonSync
    model Models::KeyPair

    # See Models::JsonSync
    def to_h
      { 'ssh_keys' => map(&:to_h).map(&:stringify_keys) }
    end
  end
end
