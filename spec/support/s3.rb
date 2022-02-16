require 'fog/aws'

module Support
  module S3
    class FakeObject
      attr_accessor :key, :size, :last_modified
      def initialize(key)
        @key  = key
        @size = "0"
      end
    end

    class FakeService
      class GetClass

        def initialize(something)
          @something = something
        end

        def get(_bucket_name, params)
          raise "'prefix' is required" if params.empty? || !params[:prefix]
          @something.params = params
          @something
        end
      end
      attr_reader :directories
      def initialize(directory)
        @directories = GetClass.new(directory)
      end
    end

    class FakeBucket
      attr_accessor :params
      def initialize(objects)
        @objects = Array(objects)
      end

      def files
        @objects.select { |o| o.key.start_with? params[:prefix] }
      end

      def create(key)
        @objects << FakeObject.new(key)
      end

      alias_method :<<, :create
    end

    extend ActiveSupport::Concern

    included do
      before(:each)    { allow(::Fog::Storage).to receive(:new).and_return(s3_service) }
      let(:s3_service) {
        service = FakeService.new(s3_bucket)
        service
      }
      let(:s3_bucket)  { FakeBucket.new(s3_objects) }
      let(:s3_objects) { [] }
    end
  end
end
