require 'travis'
require 'travis/topaz'

module Services
  module Trials
    class Add
      attr_reader :owner

      def initialize(owner)
        @owner = owner
      end
    end
  end
end
