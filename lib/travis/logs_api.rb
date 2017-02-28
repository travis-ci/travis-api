require 'json'
require 'faraday'

require 'travis/model/remote_log'

module Travis
  class LogsApi
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
        raise LogsApi::Error, "failed to write content job_id=#{job_id}"
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
