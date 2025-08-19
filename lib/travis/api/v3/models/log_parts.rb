require 'forwardable'

module Travis::API::V3::Models
  class LogParts
    extend Forwardable

    def_delegators :remote_log

    attr_accessor :remote_log, :job, :content

    def initialize(remote_log: nil, job: nil, content: true)
      @remote_log = remote_log
      @job = job
      @content = content
    end

    def log_parts
      content ? remote_log : remote_log.map { |rl| rl.as_info_json.compact }
    end

    def repository_private?
      job.repository.private?
    end

    def repository
      @repository ||= Travis::API::V3::Models::Repository.find(job.repository.id)
    end
  end
end
