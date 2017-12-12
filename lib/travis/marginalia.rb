# frozen_string_literal: true

require 'marginalia'
require 'active_record/connection_adapters/postgresql_adapter'

module Travis
  class Marginalia
    class << self
      def setup
        ::Marginalia.install
      end
    end
  end
end
