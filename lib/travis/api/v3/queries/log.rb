module Travis::API::V3
  class Queries::Log < Query
    require 'net/http'
    require 'uri'

    def find(job)
      #check for the log in the Logs DB
      log = Models::Log.find_by_job_id(job.id)

      raise EntityMissing, 'log not found'.freeze if log.nil?

      p log.archived_at

      #if the log has been archived, go to s3
      if log.archived_at
        ## if it's not there then fetch it from S3, and return it wrapped as a compatible log_parts object with a hard coded #number (log_parts have a number) and the parts chunked (not sure how to do this)
        archived_log_path = archive_url("/jobs/#{params[:job.id]}/log.txt")
        p archived_log_path
        content = open(Net::HTTP.get(URI.parse(archived_log_path)))
        p content
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
  end
end
