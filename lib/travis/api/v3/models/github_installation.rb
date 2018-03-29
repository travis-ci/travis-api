module Travis::API::V3
  class Models::GithubInstallation < Model
  	belongs_to :owner, polymorphic: true  
  end
end