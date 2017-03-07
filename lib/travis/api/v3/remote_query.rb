require 'fog/aws'
require 'fog/google'

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
      storage_files
    end

    def remove
      caches = fetch
      caches.each do |cache|
        cache.destroy
      end
    end

    private

    def storage_files
      files = storage_bucket.files
      puts "DEBUG CACHE RESULTS LOGGING: number of caches #{files.length}"
      files
    end

    def storage_bucket
      bucket = []
      bucket << s3_bucket
      bucket << gcs_bucket
      bucket
    end

    def prefix
      warn 'prefix in RemoteQuery called. If you wanted a prefix filter please implement it in the subclass.'
      ''
    end

    def s3_bucket
      s3 = Fog::Storage.new(aws_access_key_id: s3_config[:access_key_id], aws_secret_access_key: s3_config[:secret_access_key], provider: 'AWS')
      s3.directories.get(s3_config[:bucket_name], prefix: prefix)
    end

    def gcs_bucket
      # gcs = Fog::Storage.new(provider: "Google", google_storage_access_key_id: gcs_config[:json_key][:private_key_id], google_storage_secret_access_key: gcs_config[:json_key][:private_key])
      gcs = Fog::Storage::Google.new(google_json_key_string: gcs_config[:json_key], google_project: gcs_config[:google_project])
      gcs.directories.get(gcs_config[:bucket_name], prefix: prefix)
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
