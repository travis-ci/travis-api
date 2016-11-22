module Travis
  module GitHub
    def gh
      GH.with(token: github_token)
    end

    def github_token
      admin = repository.find_admin
      raise "Error: No Admin for this repository." unless admin
      admin.github_oauth_token
    end
  end
end
