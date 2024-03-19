module Travis::API::V3
  class LogToken
    attr_accessor :job_id, :repo_can_write

    def self.find(token)
      key = "l:#{token}"
      new(redis.hget(key, :job_id).to_i, !!redis.hget(key, :repo_can_write))
    end

    def self.create(job, user_id)
      repo_can_write = !!job.repository.users.where(id: user_id, permissions: { push: true }).first

      token = SecureRandom.urlsafe_base64(16)
      redis.hset("l:#{token}", :job_id, job.id)
      redis.hset("l:#{token}", :repo_can_write, repo_can_write.to_s)
      redis.expire("l:#{token}", 1.day)
      token
    end

    def self.redis
      Travis.redis
    end

    def initialize(job_id, repo_can_write)
      self.job_id = job_id
      self.repo_can_write = repo_can_write
    end

    def matches?(job)
      job_id == job.id
    end

  end
end
