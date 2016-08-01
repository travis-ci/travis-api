require 'travis'
require 'travis/topaz'

module Services
  module Trials
    class GetTotal
      attr_reader :owner

      def initialize(owner)
        @owner = owner
      end

      def call
        Travis.redis.get("trial:#{owner}")
      end
    end
  end
end