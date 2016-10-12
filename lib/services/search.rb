module Services
  class Search
    LOGIN    = %r{^[\w\-_]+$}
    EMAIL    = %r{.+@.+}
    SLUG     = %r{^[\w\-_]+/[\w\-_.]+$}
    BUILD    = %r{^([\w\-_]+/[\w\-_.]+)[#\s]+(\d+)$}
    JOB      = %r{^([\w\-_]+/[\w\-_.]+)[#\s]+(\d+\.\d+)$}
    GH_USER  = %r{^https?://github\.com/([\w\-_]+)/?$}
    GH_REPO  = %r{^https?://github\.com/([\w\-_]+/[\w\-_.]+)(?:/.*)?$}
    TR_USER  = %r{^https?://(?:become\.)?travis-ci\.(?:com|org)(?:/profile)?/([\w\-_]+)/?$}
    TR_REPO  = %r{^https?://travis-ci\.(?:com|org)/([\w\-_]+/[\w\-_.]+)(?:/[\w\-_.]*)?$}
    TR_BUILD = %r{^https?://travis-ci\.(?:com|org)/[\w\-_]+/[\w\-_.]+/builds/(\d+)?$}
    TR_JOB   = %r{^https?://travis-ci\.(?:com|org)/[\w\-_]+/[\w\-_.]+/jobs/(\d+)?$}
    URL      = %r{^https?://}
    EX_BY_ID = %r{^(build|job|request) (\d+)$}
    EX_REPO  = %r{^(repo|repository) (\d+)$}
    EX_USER  = %r{^user (\d+)$}
    EX_ORG   = %r{^organization (\d+)$}

    attr_reader :q

    def initialize(query)
      @q = query
    end

    def call
      results
    end

    private

    def results
      results = [explicit_result]
      results = [users, orgs, repos, builds, jobs] if results.all?(&:blank?)
      results = [::User.where("lower(name) = ?", q.downcase), ::Organization.where("lower(name) = ?", q.downcase)] if results.all?(&:blank?)
      results.flatten.compact
    end

    def find(klass, field, value = q)
      "::#{klass}".constantize.find_by(field => value)
    end

    def explicit_result
      case q
      when EX_BY_ID then find($1.capitalize, :id, $2)
      when EX_REPO  then ::Repository.find_by(id: $2)
      when EX_USER  then ::User.find_by(id: $1) || ::User.where(github_id: $1)
      when EX_ORG   then ::Organization.find_by(id: $1) || ::Organization.where(github_id: $1)
      end
    end

    def users
      case q
      when LOGIN    then ::User.where("lower(login) = ?", q.downcase)
      when EMAIL    then ::User.where(email: q) + ::Email.where(email: q).try(:map) { |e| e.user }
      when GH_USER  then ::User.where("lower(login) = ?", $1.downcase)
      when TR_USER  then ::User.where("lower(login) = ?", $1.downcase)
      end
    end

    def orgs
      case q
      when LOGIN    then ::Organization.where("lower(login) = ?", q.downcase)
      when GH_USER  then ::Organization.where("lower(login) = ?", $1.downcase)
      when TR_USER  then ::Organization.where("lower(login) = ?", $1.downcase)
      when URL      then ::Organization.where(homepage: q)
      end
    end

    def repos
      case q
      when SLUG     then ::Repository.by_slug(q).first
      when LOGIN    then ::Repository.where("lower(name) = ?", q.downcase)
      when GH_REPO  then ::Repository.by_slug($1).first
      when TR_REPO  then ::Repository.by_slug($1).first
      end
    end

    def builds
      case q
      when TR_BUILD then ::Build.where(id: $1)
      when BUILD    then build($1, $2)
      end
    end

    def jobs
      case q
      when TR_JOB   then ::Job.where(id: $1)
      when JOB      then job($1, $2)
      end
    end

    def build(slug, number)
      ::Repository.by_slug(slug).first.builds.where(number: number)
    end

    def job(slug, number)
      ::Repository.by_slug(slug).first.jobs.where(number: number)
    end
  end
end
