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

    # def remove(caches)
    #   caches.each do |cache|
    #     puts "*********"
    #     puts cache
    #     # cache.destroy
    #   end
    # end

    class GcsWrapper
      attr_reader :content_length, :key, :branch, :last_modified, :source

      def initialize(object)
        @content_length  = object.size
        @key             = object.name
        @branch          = object.name
        @last_modified   = object.updated
        @source          = 'gcs'
      end
    end

    class S3Wrapper
      attr_reader :content_length, :key, :branch, :last_modified, :source

      def initialize(object)
        @content_length  = object.content_length
        @key             = object.key
        @branch          = object.key
        @last_modified   = object.last_modified
        @source          = 's3'
      end
    end

    private

    def storage_objects
      objects = []
      s3_bucket.each { |object| objects << object } if s3_config
      gcs_bucket.each { |object| objects << object } if gcs_config
      puts "DEBUG CACHE RESULTS LOGGING: number of S3 & GCS caches #{objects.length}"
      objects
    end

    def prefix
      warn 'prefix in RemoteQuery called. If you wanted a prefix filter please implement it in the subclass.'
      ''
    end

    def s3_bucket
      s3 = Fog::Storage.new(aws_access_key_id: s3_config[:access_key_id], aws_secret_access_key: s3_config[:secret_access_key], provider: 'AWS')
      files = s3.directories.get(s3_config[:bucket_name], prefix: prefix).files
      #put each file into an array
      s3_files = []
      files.map { |file| s3_files << S3Wrapper.new(file) }
      s3_files
    end

    def gcs_bucket
      gcs     = ::Google::Apis::StorageV1::StorageService.new
      json_key_io = StringIO.new(gcs_config[:json_key])

      gcs.authorization = ::Google::Auth::ServiceAccountCredentials.make_creds(
        json_key_io: json_key_io,
        scope: [
          'https://www.googleapis.com/auth/devstorage.read_write'
        ]
      )
      items = gcs.list_objects(gcs_config[:bucket_name], prefix: prefix).items
      #put each item into an array
      gcs_items = []
      return gcs_items if items.nil?
      items.map { |item| gcs_items << GcsWrapper.new(item) }
      gcs_items
    end

    def config
      Travis.config.to_h
    end

    def s3_config
      raise NotImplemented
    end

    def gcs_config
      raise NotImplemented
    end
  end
end
