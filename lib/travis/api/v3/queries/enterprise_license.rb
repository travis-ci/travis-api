module Travis::API::V3
  class Queries::EnterpriseLicense < Query
    def active_users
      Models::Email
      .joins("INNER JOIN commits c ON LOWER(c.committer_email) = LOWER(emails.email)")
      .select('DISTINCT email')
    end
  end
end