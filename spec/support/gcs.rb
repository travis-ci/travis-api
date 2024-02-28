require 'google/apis/storage_v1'

module Support
  module GCS
    class FakeObject
      attr_accessor :key, :size
      def initialize(key, options = {})
        @key  = key
        @size = options[:size] || "0"
      end
    end

    class FakeService
      def authorization=(auth)
        true
      end

      def bucket(*args)
        FakeObjects.new
      end
    end

    class FakeObjects
      def files
        []
      end
    end

    extend ActiveSupport::Concern

    included do
      before :each do
        allow(::Google::Cloud::Storage).to receive(:new).and_return(gcs_storage)
      end
      let(:gcs_storage) { FakeService.new }
    end
  end
end
