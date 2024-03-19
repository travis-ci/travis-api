
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
      attr_reader :buckets
      def initialize(bucket, objects)
        @buckets = [bucket]
        @objects = FakeBucket.new(objects)
      end

      def list_objects(params = {})
        prefix = params[:prefix] || ""
        FakeBucket.new(@objects.contents.select { |o| o.key.start_with? prefix })
      end
    end

    class FakeBucket
      attr_reader :contents
      def initialize(objects)
        @contents = objects
      end

      def list_objects(params = {})
        params.each_key { |key| raise "cannot fake #{key}" unless key == :prefix }
        prefix = params[:prefix] || ""
        FakeBucket.new(@contents.select { |o| o.key.start_with? prefix })
      end

      def create(key)
        contents << FakeObject.new(key)
      end

      alias_method :<<, :create
    end

    extend ActiveSupport::Concern

    included do
      before(:each)    { allow(Aws::S3::Client).to receive(:new).and_return(s3_service) }
      let(:s3_service) {
        service = FakeService.new(s3_bucket, s3_objects)
        service
      }
      let(:s3_bucket)  { FakeBucket.new(s3_objects) }
      let(:s3_objects) { [] }
    end
  end
end
