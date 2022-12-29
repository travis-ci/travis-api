
module Travis::API::V3
  class Models::ScanResult
    attr_reader :id, :log_id, :job_id, :owner_id, :owner_type, :created_at, :formatted_content, :issues_found, :archived, :purged_at,
      :job_number, :build_id, :build_number, :job_finished_at, :commit_sha, :commit_compare_url, :commit_branch, :repository_id

    def initialize(attributes = {})
      @id = attributes.fetch('id')
      @log_id = attributes.fetch('log_id')
      @job_id = attributes.fetch('job_id')
      @owner_id = attributes.fetch('owner_id')
      @owner_type = attributes.fetch('owner_type')
      @created_at = attributes.fetch('created_at')
      @formatted_content = attributes.fetch('formatted_content')
      @issues_found = attributes.fetch('issues_found')
      @archived = attributes.fetch('archived')
      @purged_at = attributes.fetch('purged_at')
      @job_number = attributes.fetch('job_number')
      @build_id = attributes.fetch('build_id')
      @build_number = attributes.fetch('build_number')
      @job_finished_at = attributes.fetch('job_finished_at')
      @commit_sha = attributes.fetch('commit_sha')
      @commit_compare_url = attributes.fetch('commit_compare_url')
      @commit_branch = attributes.fetch('commit_branch')
      @repository_id = attributes.fetch('repository_id')
    end
  end
end
