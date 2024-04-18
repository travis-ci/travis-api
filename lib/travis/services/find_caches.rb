require 'aws-sdk-s3'
require 'google-cloud-storage'
require 'travis/services/base'

module Travis
  module Services
    class FindCaches < Base
      register :find_caches

      class S3Wrapper
        attr_reader :repository, :s3_object

        def initialize(repository, s3_object)
          @repository = repository
          @s3_object  = s3_object
        end

        def source
          'S3'
        end

        def last_modified
          s3_object.last_modified
        end

        def size
          Integer(s3_object.size)
        end

        def slug
          File.basename(s3_object.key, '.tbz')
        end

        def branch
          s3_object.key[%r{^(.*)/(.*)/[^/]+$}, 2]
        end

        def destroy
          Travis.logger.info "action=delete backend=s3 s3_object=#{s3_object.key}"
          s3_object.destroy
        end

        def temporary_url
          s3_object.temporary_url
        end

        def content
          s3_object.content
        end
      end

      class GcsWrapper
        attr_reader :storage, :bucket_name, :repository, :cache_object

        def initialize(storage, bucket_name, repository, cache_object)
          @storage      = storage
          @bucket_name  = bucket_name
          @repository   = repository
          @cache_object = cache_object
        end

        def source
          'GCS'
        end

        def last_modified
          cache_object.updated_at
        end

        def size
          Integer(cache_object.size)
        end

        def slug
          File.basename(cache_object.name, '.tbz')
        end

        def branch
          cache_object.name[%r{^(.*)/(.*)/[^/]+$}, 2]
        end

        def destroy
          Travis.logger.info "action=delete backend=gcs bucket_name=#{bucket_name} cache_name=#{cache_object.name}"
          storage.delete_object(bucket_name, cache_object.name)
        rescue Google::Apis::ClientError
        end

        def content
          io = StringIO.new
          storage.get_object(bucket_name, cache_object.name, download_dest: io)
          io.rewind
          io.read
        end
      end

      def run
        return [] unless setup?
        raise Travis::AuthorizationDenied unless authorized?

        c = caches(prefix: prefix)
        c.select! { |o| o.slug.include?(params[:match]) } if params[:match]
        c
      end

      private

        def setup?
          return true if valid_cache_options?

          logger.warn "[services:find-caches] cache settings incomplete"
          false
        end

        def authorized?
          current_user && repo && current_user.permission?(:push, repository_id: repo.id)
        end

        def repo
          @repo ||= run_service(:find_repo, params)
        end

        def branch
          params[:branch].presence
        end

        def prefix
          prefix = "#{repo.vcs_id || repo.github_id}/"
          prefix << branch << '/' if branch
          prefix
        end

        def caches(options = {})
          if @caches
            return @caches
          end

          cache_objects = []
          fetch_s3(cache_objects, options) if valid_s3?
          fetch_gcs(cache_objects, options) if valid_gcs?

          cache_objects.compact
        end

        def s3_client
          config = cache_options[:s3]&.to_h
          if config[:endpoint]
            Aws::S3::Client.new(
              credentials: Aws::Credentials.new(
                config[:access_key_id],
                config[:secret_access_key]
              ),
              region: config[:region] || 'us-east-2',
              endpoint: config[:endpint]
            )
          else
            Aws::S3::Client.new(
              credentials: Aws::Credentials.new(
                config[:access_key_id],
                config[:secret_access_key]
              ),
              region: config[:region] || 'us-east-2',
            )
          end
        end

        def fetch_s3(cache_objects, options)
          config = cache_options[:s3]&.to_h
          svc = s3_client
          files = svc.list_objects(bucket: config[:bucket_name], prefix: options[:prefix])
          files.contents.each { |object| cache_objects << S3Wrapper.new(repo, object) }
        end

        def fetch_gcs(cache_objects, options)
          config = cache_options[:gcs].to_h
          ENV['STORAGE_CREDENTIALS_JSON'] = JSON.dump(config[:json_key]) # store in file maybe? credentials param doesn't allow json
          storage = Google::Cloud::Storage.new
          bucket_name = config[:bucket_name]

          gcs_bucket = storage.bucket config[:bucket_name]

          items = gcs_bucket.files
          items&.each { |object| cache_objects << GcsWrapper.new(storage, bucket_name, repo, object) }
        end

        def cache_options
          Travis.config.to_h.fetch(:cache_options) { {} }
        end

        def valid_cache_options?
          valid_s3? || valid_gcs?
        end

        def valid_s3?
          (s3_config  = cache_options[:s3]) && s3_config[:access_key_id] && s3_config[:secret_access_key] && s3_config[:bucket_name]
        end

        def valid_gcs?
          (gcs_config = cache_options[:gcs]) && gcs_config[:json_key] && gcs_config[:bucket_name]
        end
    end
  end
end
