module Travis::API::V3
  class Queries::Log < Query
    require 'net/http'
    require 'uri'

    FORMAT = "Log removed by %s at %s"

    def find(job)
      #check for the log in the Logs DB
      log = Models::Log.find_by_job_id(job.id)

      raise EntityMissing, 'log not found'.freeze if log.nil?
      #if the log has been archived, go to s3
      if log.archived_at
        ## if it's not there then fetch it from S3, and return it wrapped as a compatible log_parts object with a hard coded #number (log_parts have a number) and the parts chunked (not sure how to do this)
        archived_log_path = archive_url("/jobs/#{job.id}/log.txt")
        content = Net::HTTP.get(URI.parse(archived_log_path))
        log_parts = []

        content.each_line.with_index do |line, number|
          log_part = Models::LogPart.new(log_id: log.id, content: line.chomp, number: number, created_at: log.created_at)
          log_parts << log_part
        end
        log.log_parts = log_parts
      end
      log
    end

    def archive_url(path)
      "https://s3.amazonaws.com/#{hostname('archive')}#{path}"
    end

    def hostname(name)
      "#{name}#{'-staging' if Travis.env == 'staging'}.#{Travis.config.host.split('.')[-2, 2].join('.')}"
    end

    def delete(user, job)
      log = Models::Log.find_by_job_id(job.id)
      raise EntityMissing, 'log not found'.freeze if log.nil?
      raise LogAlreadyRemoved if log.removed_at || log.removed_by
      raise JobUnfinished unless job.finished?

      removed_at = Time.now

      message = FORMAT % [current_user.name, removed_at.utc]
      log.clear!
      log.update_attributes!(
        :content => nil,
        :aggregated_at => nil,
        :archived_at => nil,
        :removed_at => removed_at,
        :removed_by => user
      )
      log.parts.create(content: message, number: 1, final: true)
      log
    end
  end
end
