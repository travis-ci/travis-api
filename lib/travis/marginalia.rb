# frozen_string_literal: true

require 'marginalia'
require 'active_record/connection_adapters/postgresql_adapter'
require 'thread'

module Marginalia
  module Comment
    def self.reset!
      @endpoint = nil
    end

    def self.endpoint=(endpoint)
      @endpoint = endpoint
    end

    def self.endpoint
      @endpoint
    end
  end
end

module Travis
  class Marginalia
    class << self
      def setup
        ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.module_eval do
          include ::Marginalia::ActiveRecordInstrumentation
        end

        ::Marginalia.application_name = 'api'
        ::Marginalia::Comment.components = [:application, :endpoint]

        # todo do this before every request
        ::Marginalia::Comment.reset!
      end
    end
  end
end
