module Travis::API::V3
  class Models::Execution
    attr_reader :id, :os, :instance_size, :arch, :virtualization_type, :queue, :job_id, :repository_id, :owner_id,
                :owner_type, :plan_id, :sender_id, :credits_consumed, :started_at, :finished_at, :created_at,
                :updated_at

    def initialize(attributes = {})
      @id = attributes.fetch('id')
      @os = attributes.fetch('os')
      @instance_size = attributes.fetch('instance_size')
      @arch = attributes.fetch('arch')
      @virtualization_type = attributes.fetch('virtualization_type')
      @queue = attributes.fetch('queue')
      @job_id = attributes.fetch('job_id')
      @repository_id = attributes.fetch('repository_id')
      @owner_id = attributes.fetch('owner_id')
      @owner_type = attributes.fetch('owner_type')
      @plan_id = attributes.fetch('plan_id')
      @sender_id = attributes.fetch('sender_id')
      @credits_consumed = attributes.fetch('credits_consumed')
      @started_at = attributes.fetch('started_at')
      @finished_at = attributes.fetch('finished_at')
      @created_at = attributes.fetch('created_at')
      @updated_at = attributes.fetch('updated_at')
    end
  end
end
