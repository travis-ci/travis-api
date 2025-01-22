require 'google/cloud/storage'
require 'aws-sdk-s3'

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
      bucket = gcs_connection.bucket gcs_config[:bucket_name]
      file = bucket.file key
      d = file.download
      d.rewind
      d.read
    end

    def remove(objects)
      objects.each do |object|
        raise SourceUnknown "#{object.source} is an unknown source." unless ['s3', 'gcs'].include? object.source
        send "#{object.source}_delete", object.key
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
        @last_modified   = object.updated_at
        @source          = 'gcs'.freeze
        @key             = object.name
      end
    end

    class S3Wrapper
      attr_reader :content_length, :name, :branch, :last_modified, :source, :key, :body

      def initialize(object, body)
        @content_length  = object.size
        @name            = object.key
        @branch          = object.key
        @last_modified   = object.last_modified
        @source          = 's3'.freeze
        @key             = object.key
        @body            = body if object.key.include?("/log.txt")
      end
    end

    private

    def storage_objects
      objects = []
      s3_objects.each { |object| objects << object } if s3_config
      gcs_objects.each { |object| objects << object } if gcs_config
      objects
    end

    def s3_connection
      if s3_config[:hostname]
        Aws::S3::Client.new(
          credentials: Aws::Credentials.new(
            s3_config[:access_key_id],
            s3_config[:secret_access_key]
          ),
          region: s3_config[:region] || 'us-east-2',
          endpoint: endpoint
        )
      else
        Aws::S3::Client.new(
          credentials: Aws::Credentials.new(
            s3_config[:access_key_id],
            s3_config[:secret_access_key]
          ),
          region: s3_config[:region] || 'us-east-2'
        )
      end
    end

    def endpoint
      s3_config[:hostname]&.index('http') == 0 ? s3_config[:hostname] : "https://#{s3_config[:hostname]}"
    end

    def s3_objects
      files = s3_connection.list_objects(bucket: s3_config[:bucket_name], prefix: prefix)
      files&.contents.map { |file| S3Wrapper.new(file, file.key.include?("/log.txt") ? s3_get_body(file.key) : nil) }
    end

    def s3_get_body(key)
      s3_connection.get_object(bucket: s3_config[:bucket_name], key: key)&.body&.read
    end

    def s3_delete(key)
      s3_connection.delete_object(bucket: s3_config[:bucket_name], key: key)
    end

    def gcs_connection
      ENV['STORAGE_CREDENTIALS_JSON'] = JSON.dump(gcs_config[:json_key]) # store in file maybe? credentials param doesn't allow json
      ::Google::Cloud::Storage.new
    end

    def gcs_bucket
      @_gcs_bucket ||= gcs_connection.bucket gcs_config[:bucket_name]
    end

    def gcs_objects
      items = gcs_bucket.files prefix: prefix
      return [] if items.nil?
      items.map { |item| GcsWrapper.new(item) }
    end

    def gcs_delete(key)
      file = gcs_bucket.file (key)
      file.delete
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
