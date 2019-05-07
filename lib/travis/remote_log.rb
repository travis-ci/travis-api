require 'forwardable'
require 'json'

require 'faraday'
require 'faraday_middleware'
require 'virtus'

module Travis
  class RemoteLog
    class << self
      extend Forwardable

      def_delegators :client, :find_by_job_id, :find_by_id,
        :find_id_by_job_id, :find_parts_by_job_id, :write_content_for_job_id

      def_delegators :archive_client, :fetch_archived_url

      private def client
        @client ||= Client.new(
          url: Travis.config.logs_api.url,
          token: Travis.config.logs_api.token
        )
      end

      private def archive_client
        @archive_client ||= ArchiveClient.new(
          access_key_id: archive_s3_config[:access_key_id],
          secret_access_key: archive_s3_config[:secret_access_key],
          host: archive_s3_config[:host],
          region: archive_s3_config[:region],
          endpoint: archive_s3_config[:endpoint],
          bucket_name: archive_s3_config[:bucket_name]
        )
      end

      private def archive_s3_config
        @archive_s3_config ||= Travis.config.log_options.s3.to_h
      end
    end

    include Virtus.model(nullify_blank: true)

    attribute :aggregated_at, Time
    attribute :archive_verified, Boolean, default: false
    attribute :archived_at, Time
    attribute :archiving, Boolean, default: false
    attribute :content, String
    attribute :created_at, Time
    attribute :id, Integer
    attribute :job_id, Integer
    attribute :purged_at, Time
    attribute :removed_at, Time
    attribute :removed_by_id, Integer
    attribute :updated_at, Time

    def job
      @job ||= Job.find(job_id)
    end

    def removed_by
      return nil unless removed_by_id
      @removed_by ||= User.find(removed_by_id)
    end

    def removed?
      !removed_by_id.nil?
    end

    def parts(after: nil, part_numbers: [])
      return solo_part if removed? || aggregated?
      self.class.find_parts_by_job_id(
        job_id, after: after, part_numbers: part_numbers
      )
    end

    alias log_parts parts

    private def solo_part
      [
        RemoteLogPart.new(
          number: 0,
          content: content,
          final: true
        )
      ]
    end

    def aggregated?
      !!aggregated_at
    end

    def archived?
      !!(!archived_at.nil? && archive_verified?)
    end

    def archived_url(expires: nil)
      @archived_url ||= self.class.fetch_archived_url(job_id, expires: expires)
    end

    def to_json(chunked: false, after: nil, part_numbers: [])
      as_json(
        chunked: chunked,
        after: after,
        part_numbers: part_numbers
      ).to_json
    end

    def as_json(chunked: false, after: nil, part_numbers: [])
      ret = {
        'id' => id,
        'job_id' => job_id,
        'type' => 'Log'
      }

      unless removed_at.nil?
        ret['removed_at'] = removed_at.utc.to_s
        ret['removed_by'] = removed_by.name || removed_by.login
      end

      if chunked
        ret['parts'] = parts(
          after: after,
          part_numbers: part_numbers
        ).map(&:as_json)
      else
        ret['body'] = content
      end

      { 'log' => ret }
    end

    def clear!(user = nil)
      message = ''
      removed_by = nil

      if user.respond_to?(:name) && user.respond_to?(:id)
        message = "Log removed by #{user.name} at #{Time.now.utc}"
        removed_by = user.id
      end

      updated = self.class.write_content_for_job_id(
        job_id,
        content: message,
        removed_by: removed_by
      )

      attributes.keys.each do |k|
        send("#{k}=", updated.send(k))
      end

      message
    end

    class Client
      Error = Class.new(StandardError)

      def initialize(url: '', token: '')
        @url = url
        @token = token
      end

      attr_reader :url, :token
      private :url
      private :token

      def find_by_id(log_id)
        find_by('id', log_id)
      end

      def find_by_job_id(job_id)
        find_by('job_id', job_id)
      end

      def find_id_by_job_id(job_id)
        resp = conn.get do |req|
          req.url "logs/#{job_id}/id"
          req.params['source'] = 'api'
        end
        return nil unless resp.success?
        JSON.parse(resp.body).fetch('id')
      end

      def find_parts_by_job_id(job_id, after: nil, part_numbers: [])
        resp = conn.get do |req|
          req.url "log-parts/#{job_id}"
          req.params['after'] = after unless after.nil?
          unless part_numbers.empty?
            req.params['part_numbers'] = part_numbers.map(&:to_s).join(',')
          end
        end
        unless resp.success?
          raise Error, "failed to fetch log-parts job_id=#{job_id}"
        end
        JSON.parse(resp.body).fetch('log_parts').map do |part|
          RemoteLogPart.new(part)
        end
      end

      def write_content_for_job_id(job_id, content: '', removed_by: nil)
        resp = conn.put do |req|
          req.url "logs/#{job_id}"
          req.params['source'] = 'api'
          req.params['removed_by'] = removed_by unless removed_by.nil?
          req.headers['Content-Type'] = 'application/octet-stream'
          req.body = content
        end
        unless resp.success?
          raise Error, "failed to write content job_id=#{job_id}"
        end
        RemoteLog.new(JSON.parse(resp.body))
      end

      private def find_by(by, id)
        resp = conn.get do |req|
          req.url "logs/#{id}", by: by
          req.params['source'] = 'api'
        end
        return nil unless resp.success?
        RemoteLog.new(JSON.parse(resp.body))
      end

      private def conn
        @conn ||= Faraday.new(http_options.merge(url: url)) do |c|
          c.request :authorization, :token, token
          c.request :retry, max: 5, interval: 0.1, backoff_factor: 2
          c.use :instrumentation
          c.use OpenCensus::Trace::Integrations::FaradayMiddleware if Travis::Api::App::Middleware::OpenCensus.enabled?
          c.adapter :net_http_persistent
        end
      end

      private def http_options
        { ssl: Travis.config.ssl.to_h }
      end
    end

    class ArchiveClient
      def initialize(access_key_id: nil, secret_access_key: nil, host: nil, endpoint: nil, region: nil, bucket_name: nil)
        @bucket_name = bucket_name
        @s3 = Fog::Storage.new(
          aws_access_key_id: access_key_id,
          aws_secret_access_key: secret_access_key,
          instrumentor: ActiveSupport::Notifications,
          connection_options: { instrumentor: ActiveSupport::Notifications },
          host: host,
          endpoint: endpoint,
          region: region,
          provider: 'AWS',
          path_style: true
        )
      end

      attr_reader :s3, :bucket_name
      private :s3
      private :bucket_name

      def fetch_archived_url(job_id, expires: nil)
        expires = expires || Time.now.to_i + 30
        file = fetch_archived(job_id)
        return nil if file.nil?
        return file.public_url if file.public?
        file.url(expires)
      end

      private def fetch_archived(job_id)
        candidates = s3.directories.get(
          bucket_name,
          prefix: "jobs/#{job_id}/log.txt"
        ).files

        return nil if candidates.empty?
        candidates.first
      end
    end
  end

  class RemoteLogPart
    include Virtus.model(nullify_blank: true)

    attribute :content, String
    attribute :final, Boolean
    attribute :id, Integer
    attribute :number, Integer

    def as_json(**_)
      attributes.slice(*%i(content final number))
    end
  end
end
