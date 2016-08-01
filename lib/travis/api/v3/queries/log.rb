module Travis::API::V3
  class Queries::Log < Query
    require 'net/http'
    require 'uri'

    def find(job)
      #check for the log in the DB
      log = Models::Log.find_by_job_id
      #if the log exists and has not been archived yet, then collect the log_parts and return the contents
      unless log.nil? || !log.archived_at.nil?
        log_parts = Models::Log::Part.where(log_id: log.id)
        log_data = []
        log_parts.each { |log_part| log_data << log_part.content }
        log_data
      elsif log.archived_at?
        # if it's not there then fetch it from S3.
        archived_log_path = archive_url("/jobs/#{params[:job.id]}/log.txt")

        content = open(Net::HTTP.get(URI.parse(archived_log_path)))
        archived_log_data = []
        content.each_line do |line|
          archived_log_data << line.chop
        end
        archived_log_data
      end
    end

    def archive_url(path)
      "https://s3.amazonaws.com/#{hostname('archive')}#{path}"
    end

    def hostname(name)
      "#{name}#{'-staging' if Travis.env == 'staging'}.#{Travis.config.host.split('.')[-2, 2].join('.')}"
    end
  end
end
