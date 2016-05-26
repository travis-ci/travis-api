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

      def list_objects(*args)
        FakeObjects.new
      end
    end

    class FakeObjects
      def items
        []
      end
    end

    class FakeAuthorization
    end

    extend ActiveSupport::Concern

    included do
      before :each do
        ::Google::Apis::StorageV1::StorageService.stubs(:new).returns(gcs_storage)
        ::Google::Auth::ServiceAccountCredentials.stubs(:make_creds).returns(FakeAuthorization.new)
      end
      let(:gcs_storage) { FakeService.new }
    end
  end
end