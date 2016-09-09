module Travis::API::V3
  class Queries::Caches < Query
    require 'fog/aws'

    require 'fog/google'
    require 'openssl'
    OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

    def find(repo)
      config = Travis.config.to_h.try(:[], :cache_options).to_h

      s3 = Fog::Storage.new(aws_access_key_id: config[:s3].try(:[], :access_key_id), aws_secret_access_key: config[:s3].try(:[], :secret_access_key), provider: 'AWS')

      caches = s3.directories.get(config[:s3].try(:[], :bucket_name), prefix: repo.github_id).files.to_a

      if caches.empty?
        google = Fog::Storage::Google.new(google_json_key_string: config[:gcs].try(:[], :json_key), google_project: config[:gcs].try(:[], :google_project))
        caches = google.directories.get(config[:gcs].try(:[], :bucket_name), prefix: repo.github_id).files.to_a
      end

      caches.map! do |c|
        {
          repository_id: repo.id,
          size: Integer(c.content_length),
          branch: c.key[%r{^\d+/(.*)/[^/]+$}, 1],
          last_modified: c.last_modified
        }
      end

      caches
    end

    #might want this for branch name and slug
    def filter(list)
      # sort list
      list
    end
  end
end
