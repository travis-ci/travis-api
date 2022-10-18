require 'forwardable'

module Travis::API::V3::Models
  class Log
    extend Forwardable

    def_delegators :remote_log, :id, :attributes, :archived?

    attr_accessor :remote_log, :archived_content, :job

    def initialize(remote_log: nil, archived_content: nil, job: nil)
      @remote_log = remote_log
      @archived_content = archived_content
      @job = job
    end

    def content
      archived_content || remote_log.content
    end

    def log_parts
      return remote_log.log_parts if archived_content.nil?
      [archived_log_part]
    end

    def repository_private?
      job.repository.private?
    end

    def repository
      @repository ||= Travis::API::V3::Models::Repository.find(job.repository.id)
    end

    private

    def archived_log_part
      {
        content: archived_content,
        final: true,
        number: 0
      }
    end
  end
end
