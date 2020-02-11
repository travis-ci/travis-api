require 's3'

module Support
  module S3
    class FakeObject
      attr_accessor :key, :size, :last_modified
      def initialize(key, options = {})
        @key  = key
        @size = options[:size] || "0"
      end
    end

    class FakeService
      attr_reader :buckets
      def initialize(bucket)
        @buckets = [bucket]
      end
    end

    class FakeBucket
      def initialize(objects)
        @objects = Array(objects)
      end

      def objects(params = {})
        params.each_key { |key| raise "cannot fake #{key}" unless key == :prefix }
        prefix = params[:prefix] || ""
        @objects.select { |o| o.key.start_with? prefix }
      end

      def add(key, options = {})
        @objects << FakeObject.new(key, options)
      end

      alias_method :<<, :add
    end

    extend ActiveSupport::Concern

    included do
      before(:each)    { allow(::S3::Service).to receive(:new).and_return(s3_service) }
      before(:each)    { allow(::S3::Service).to receive(:new).and_return(s3_service) }
      let(:s3_service) {
        service = FakeService.new(s3_bucket)
        allow(service.buckets).to receive(:find).and_return(s3_bucket)
        service
      }
      let(:s3_bucket)  { FakeBucket.new(s3_objects) }
      let(:s3_objects) { [] }
    end
  end
end
