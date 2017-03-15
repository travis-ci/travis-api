require 'fog/aws'
require 'fog/google'
require 'google/apis/storage_v1'

module Travis::API::V3
  class RemoteQuery < Query
    def set
      # This is for the future when we use the API to create a file on a remote
      raise NotImplemented
      fetch.create(
        key: 'file key',
        body: File.open("path to file"),
        public: false
      )
    end

    def fetch
      storage_objects
    end

    def remove(objects)
      objects.each do |object|
        if object.source == 's3'
          Travis.logger.info "action=delete backend=s3 s3_object=#{object.key}"
          @s3.delete_object(s3_config[:bucket_name], object.key)
        elsif object.source == 'gcs'
          Travis.logger.info "action=delete backend=gcs bucket_name=#{s3_config[:bucket_name]} object_key=#{object.key}"
          @gcs.delete_object(gcs_config[:bucket_name], object.key)
        else
          raise SourceUnknown "#{object.source} is an unknown source."
        end
      end
    end

    class GcsWrapper
      attr_reader :content_length, :name, :branch, :last_modified, :source, :key

      def initialize(object)
        @content_length  = object.size
        @name            = object.name
        @branch          = object.name
        @last_modified   = object.updated
        @source          = 'gcs'.freeze
        @key             = object.name
      end
    end

    class S3Wrapper
      attr_reader :content_length, :name, :branch, :last_modified, :source, :key, :body

      def initialize(object)
        @content_length  = object.content_length
        @name            = object.key
        @branch          = object.key
        @last_modified   = object.last_modified
        @source          = 's3'.freeze
        @key             = object.key
        @body            = object.body if object.key.include?("/log.txt")
      end
    end

    private

    def storage_objects
      objects = []
      s3_bucket.each { |object| objects << object } if s3_config
      gcs_bucket.each { |object| objects << object } if gcs_config
      objects
    end

    def prefix
      warn 'prefix in RemoteQuery called. If you wanted a prefix filter please implement it in the subclass.'
      ''
    end

    def s3_bucket
      @s3 = Fog::Storage.new(aws_access_key_id: s3_config[:access_key_id], aws_secret_access_key: s3_config[:secret_access_key], provider: 'AWS')
      files = @s3.directories.get(s3_config[:bucket_name], prefix: prefix).files
      files.map { |file| S3Wrapper.new(file) }
    end

    def gcs_bucket
      @gcs = ::Google::Apis::StorageV1::StorageService.new
      json_key_io = StringIO.new(gcs_config[:json_key])

      @gcs.authorization = ::Google::Auth::ServiceAccountCredentials.make_creds(
        json_key_io: json_key_io,
        scope: [
          'https://www.googleapis.com/auth/devstorage.read_write'
        ]
      )
      items = @gcs.list_objects(gcs_config[:bucket_name], prefix: prefix).items
      return [] if items.nil?
      items.map { |item| GcsWrapper.new(item) }
    end

    def config
      Travis.config.to_h
    end

    def s3_config
      # leave empty - s3_config is set in the attribute query
    end

    def gcs_config
      # leave empty - gcs_config is set in the attribute query
    end
  end
end
