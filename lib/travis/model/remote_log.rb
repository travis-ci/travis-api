require 'forwardable'
require 'json'

require 'faraday'
require 'virtus'

class RemoteLog
  class << self
    extend Forwardable

    def_delegators :client, :find_by_job_id, :find_by_id,
                   :write_content_for_job_id

    private def client
      @client ||= Client.new(
        url: Travis.config.logs_api.url,
        token: Travis.config.logs_api.token
      )
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

  def to_json
    {
      'log' => attributes.slice(
        *%i(id content created_at job_id updated_at)
      )
    }.to_json
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
      RemoteLog.new(JSON.parse(resp.body))
    end

    private def find_by(by, id)
      resp = conn.get do |req|
        req.url "/logs/#{id}", by: by
      end
      return nil unless resp.success?
      RemoteLog.new(JSON.parse(resp.body))
    end

    private def conn
      @conn ||= Faraday.new(url: url) do |c|
        c.request :authorization, :token, token
        c.request :retry, max: 5, interval: 0.1, backoff_factor: 2
        c.adapter :net_http
      end
    end
  end
end
