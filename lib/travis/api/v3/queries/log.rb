module Travis::API::V3
  class Queries::Log < Query
    require 'net/http'
    require 'uri'

    def find(job)
      #check for the log in the Logs DB
      log = Models::Log.find_by_job_id
      #if the log exists and has not been archived yet, then collect the log_parts and return the Log query object
      unless !log.archived_at.nil?
        log_parts = Models::LogPart.where(log_id: log.id).to_a
      elsif log.archived_at?
        ## if it's not there then fetch it from S3, and return it wrapped as a compatible log_parts object with a hard coded #number (log_parts have a number) and the parts chunked (not sure how to do this)
        archived_log_path = archive_url("/jobs/#{params[:job.id]}/log.txt")
        content = open(Net::HTTP.get(URI.parse(archived_log_path)))

        ## log_part model:
        ## id: nil,
        ## log_id: log.id,
        ## content: {"[INFO] Fetching org.eclipse.jface_3.11.1.v20160128-...}",
        ## number: start at 0, increment by 1,
        ## final: false,
        ## created_at: log.created_at

        # log_parts = []
        # content.each_line do |line|
        #   log_parts << line.chop
        # end
        # log_parts
      else
        raise EntityMissing, 'log not found'.freeze
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
