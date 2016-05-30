require 's3'
require 'travis/services/base'
require 'google/apis/storage_v1'

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
          s3_object.key[%r{^\d+/(.*)/[^/]+$}, 1]
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
          cache_object.updated
        end

        def size
          Integer(cache_object.size)
        end

        def slug
          File.basename(cache_object.name, '.tbz')
        end

        def branch
          cache_object.name[%r{^\d+/(.*)/[^/]+$}, 1]
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
        return [] unless setup? && permission?
        c = caches(prefix: prefix)
        c.select! { |o| o.slug.include?(params[:match]) } if params[:match]
        c
      end

      private

        def setup?
          return true if entries.any? { |entry| valid?(entry) }

          logger.warn "[services:find-caches] cache settings incomplete"
          false
        end

        def permission?
          current_user.permission?(required_role, repository_id: repo.id)
        end

        def required_role
          Travis.config.roles.find_cache || "push"
        end

        def repo
          @repo ||= run_service(:find_repo, params)
        end

        def branch
          params[:branch].presence
        end

        def prefix
          prefix = "#{repo.github_id}/"
          prefix << branch << '/' if branch
          prefix
        end

        def caches(options = {})
          if @caches
            return @caches
          end

          c = []

          entries.map do |entry|
            if config = entry[:s3]
              svc = ::S3::Service.new(config.to_h.slice(:secret_access_key, :access_key_id))
              bucket = svc.buckets.find(config.fetch(:bucket_name))

              next unless bucket

              c += bucket.objects(options).map { |object| S3Wrapper.new(repo, object) }
            elsif config = entry[:gcs]
              storage     = ::Google::Apis::StorageV1::StorageService.new
              json_key_io = StringIO.new(config.to_h[:json_key])
              bucket_name = config[:bucket_name]

              storage.authorization = ::Google::Auth::ServiceAccountCredentials.make_creds(
                json_key_io: json_key_io,
                scope: [
                  'https://www.googleapis.com/auth/devstorage.read_write'
                ]
              )

              next unless items = storage.list_objects(bucket_name, prefix: prefix).items

              items.map do |object|
                c << GcsWrapper.new(storage, bucket_name, repo, object)
              end
            end
          end

          @caches = c.compact
        end

        def entries
          collection = Travis.config.to_h.fetch(:cache_options) { [] }
          collection = [collection] unless collection.is_a? Array
          collection
        end

        def valid?(entry)
          valid_s3?(entry) or valid_gcs?(entry)
        end

        def valid_s3?(entry)
          (s3_config  = entry[:s3]) && s3_config[:access_key_id] && s3_config[:secret_access_key] && s3_config[:bucket_name]
        end

        def valid_gcs?(entry)
          (gcs_config = entry[:gcs]) && gcs_config[:json_key] && gcs_config[:bucket_name]
        end
    end
  end
end
