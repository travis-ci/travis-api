require 'forwardable'
require 'json'

require 'faraday'
require 'virtus'

module Travis
  class RemoteLog
    class << self
      extend Forwardable

      def_delegators :client, :find_by_job_id, :find_by_id,
        :find_id_by_job_id, :write_content_for_job_id

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
          bucket_name: archive_s3_bucket
        )
      end

      private def archive_s3_bucket
        @archive_s3_bucket ||= [
          Travis.env == 'staging' ? 'archive-staging' : 'archive',
          Travis.config.host.split('.')[-2, 2]
        ].flatten.compact.join('.')
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

    def parts
      # The content field is always pre-aggregated.
      []
    end

    alias log_parts parts

    def aggregated?
      !!aggregated_at
    end

    def archived?
      !!(!archived_at.nil? && archive_verified?)
    end

    def archived_url(expires: nil)
      @archived_url ||= self.class.fetch_archived_url(job_id, expires: expires)
    end

    def to_json(chunked: false)
      as_json(chunked: chunked).to_json
    end

    def as_json(chunked: false)
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
        ret['parts'] = [
          {
            'number' => 1,
            'content' => content,
            'final' => true
          }
        ]
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
          req.url "/logs/#{job_id}/id"
        end
        return nil unless resp.success?
        JSON.parse(resp.body).fetch('id')
      end

      def write_content_for_job_id(job_id, content: '', removed_by: nil)
        resp = conn.put do |req|
          req.url "/logs/#{job_id}"
          req.params['removed_by'] = removed_by unless removed_by.nil?
          req.headers['Content-Type'] = 'application/octet-stream'
          req.body = content
        end
        unless resp.success?
          raise Error, "failed to write content job_id=#{job_id}"
        end
        Travis::RemoteLog.new(JSON.parse(resp.body))
      end

      private def find_by(by, id)
        resp = conn.get do |req|
          req.url "/logs/#{id}", by: by
        end
        return nil unless resp.success?
        Travis::RemoteLog.new(JSON.parse(resp.body))
      end

      private def conn
        @conn ||= Faraday.new(url: url) do |c|
          c.request :authorization, :token, token
          c.request :retry, max: 5, interval: 0.1, backoff_factor: 2
          c.adapter :net_http
        end
      end
    end

    class ArchiveClient
      def initialize(access_key_id: nil, secret_access_key: nil, bucket_name: nil)
        @bucket_name = bucket_name
        @s3 = Fog::Storage.new(
          aws_access_key_id: access_key_id,
          aws_secret_access_key: secret_access_key,
          provider: 'AWS'
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
end
