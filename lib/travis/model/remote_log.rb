require 'virtus'

class RemoteLog
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
  attribute :removed_by, Integer
  attribute :updated_at, Time

  def job
    @job ||= Job.find(job_id)
  end

  def removed_by
    @removed_by ||= User.find(attributes[:removed_by])
  end

  def parts
    # The content field is always pre-aggregated.
    []
  end

  def aggregated?
    !!aggregated_at
  end

  def clear!
    raise NotImplementedError
  end

  def archived?
    archived_at && archive_verified?
  end

  def to_json
    {
      'log' => attributes.slice(
        *%w(id content created_at job_id updated_at)
      )
    }.to_json
  end
end
