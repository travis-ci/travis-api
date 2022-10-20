# frozen_string_literal: true

module Travis::API::V3
  class Models::ScannerCollection
    def initialize(collection, total_count)
      @collection = collection
      @total_count = total_count
    end

    def count(*)
      @total_count
    end

    def limit(*)
      self
    end

    def offset(*)
      self
    end

    def map
      return @collection.map unless block_given?

      @collection.map { |x| yield x }
    end

    def to_sql
      "scanner_query:#{Time.now.to_i}"
    end
  end
end
