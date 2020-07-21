module Travis::API::V3
  class LogToken
    attr_accessor :job_id

    def self.find(token)
      new(redis.get("l:#{token}").to_i)
    end

    def self.create(job)
      token = SecureRandom.urlsafe_base64(16)
      redis.set("l:#{token}", job.id)
      redis.expire("l:#{token}", 1.day)
      token
    end

    def self.redis
      Travis.redis
    end

    def initialize(job_id)
      self.job_id = job_id
    end

    def matches?(job)
      job_id == job.id
    end

  end
end
