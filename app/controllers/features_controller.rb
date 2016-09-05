class FeaturesController < ApplicationController
  def index
    @global_features = Features.global
    @user_features = Features.for_kind('users')
    @organization_features = Features.for_kind('organizations')
    @repository_features = Features.for_kind('repositories')
  end
end
