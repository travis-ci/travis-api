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

    def get(key)
      io = StringIO.new
      gcs_connection.get_object(gcs_config[:bucket_name], key, download_dest: io)
      io.rewind
      io.read
    end

    def remove(objects)
      objects.each do |object|
        raise SourceUnknown "#{object.source} is an unknown source." unless ['s3', 'gcs'].include? object.source
        send("#{object.source}_connection").delete_object(bucket_name_for(object), object.key)
      end
    end

    def bucket_name_for(object)
      send("#{object.source}_config")[:bucket_name]
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
      s3_objects.each { |object| objects << object } if s3_config
      gcs_objects.each { |object| objects << object } if gcs_config
      objects
    end

    def prefix
      warn 'prefix in RemoteQuery called. If you wanted a prefix filter please implement it in the subclass.'
      ''
    end

    def s3_connection
      Fog::Storage.new(
        aws_access_key_id: s3_config[:access_key_id],
        aws_secret_access_key: s3_config[:secret_access_key],
        provider: 'AWS',
        instrumentor: ActiveSupport::Notifications,
        connection_options: { instrumentor: ActiveSupport::Notifications }
      )
    end

    def s3_bucket
      s3_connection.directories.get(s3_config[:bucket_name], prefix: prefix)
    end

    def s3_objects
      files = s3_bucket.files
      files.map { |file| S3Wrapper.new(file) }
    end

    def gcs_connection
      gcs = ::Google::Apis::StorageV1::StorageService.new
      json_key_io = StringIO.new(gcs_config[:json_key])

      gcs.authorization = ::Google::Auth::ServiceAccountCredentials.make_creds(
        json_key_io: json_key_io,
        scope: [
          'https://www.googleapis.com/auth/devstorage.read_write'
        ]
      )
      gcs
    end

    def gcs_bucket
      gcs_connection.list_objects(gcs_config[:bucket_name], prefix: prefix)
    end

    def gcs_objects
      items = gcs_bucket.items
      return [] if items.nil?
      items.map { |item| GcsWrapper.new(item) }
    end

    def config
      Travis.config.to_h
    end

    def s3_config
      config["#{main_type}_options".to_sym][:s3]
    end

    def gcs_config
      config["#{main_type}_options".to_sym][:gcs]
    end
  end
end
