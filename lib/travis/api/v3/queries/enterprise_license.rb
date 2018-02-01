module Travis::API::V3
  class Queries::EnterpriseLicense < Query
    def active_users(expiration_time)
      this_year = Date.parse(expiration_time)
      last_year = this_year - 365

      Models::Email
      .joins("INNER JOIN commits c ON LOWER(c.committer_email) = LOWER(emails.email)")
      .select('DISTINCT email')
      .where("c.created_at >= '#{last_year}' AND c.created_at < '#{this_year}'")
    end
  end
end