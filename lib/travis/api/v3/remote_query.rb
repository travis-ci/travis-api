require 'fog/aws'
require 'fog/google'

module Travis::API::V3
  class RemoteQuery < Query

    require 'openssl'
    OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

    def set
    end

    def fetch(repo)
      @repo = repo
      storage_files
    end

    def get(key)
    end

    def remove
    end

    private

    def storage_files
      storage_bucket.files
    end

    def storage_bucket
      aws_bucket = s3_bucket
      return aws_bucket if aws_bucket
      gcs_bucket
    end

    def prefix
      binding.pry
      name = params[:match].to_s
      name = "#{@repo.id}/#{params[:branch]}" if name.empty?
      name
    end

    def s3_bucket
      s3 = Fog::Storage.new(aws_access_key_id: s3_config[:access_key_id], aws_secret_access_key: s3_config[:secret_access_key], provider: 'AWS')
      s3.directories.get(s3_config[:bucket_name], prefix: prefix)
    end

    def gcs_bucket
      gcs = Fog::Storage::Google.new(google_json_key_string: gcs_config[:json_key], google_project: gcs_config[:google_project])
      gcs.directories.get(gcs_config[:bucket_name], prefix: prefix)
    end

    def config
      Travis.config
    end

    def s3_config
      config.s3 || []
    end

    def gcs_config
      config.gcs || []
    end
  end
end
