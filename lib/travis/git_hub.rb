module Travis
  module GitHub
    def gh
      GH.with(token: github_token)
    end

    def github_token
      admin = repository.find_admin
      admin.github_oauth_token if admin
    end
  end
end
