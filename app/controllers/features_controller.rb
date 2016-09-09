class FeaturesController < ApplicationController
  include ApplicationHelper

  def index
    @global_features       = Features.global
    @user_features         = Features.for_kind('users')
    @organization_features = Features.for_kind('organizations')
    @repository_features   = Features.for_kind('repositories')
    @current_user = current_user
  end

  def disable
    Features.disable_for_all(params[:feature])
    Services::EventLogs::Add.new(current_user, "disabled feature #{format_feature(params[:feature])} globally").call
    flash[:notice] = "Feature #{format_feature(params[:feature])} disabled."
    redirect_to features_path
  end

  def enable
    Features.enable_for_all(params[:feature])
    Services::EventLogs::Add.new(current_user, "enabled feature #{format_feature(params[:feature])} globally").call
    flash[:notice] = "Feature #{format_feature(params[:feature])} enabled."
    redirect_to features_path
  end

  def show
    @kind    = params[:kind]
    @feature = params[:feature]
    @members = Features.members(@kind, @feature)
  end
end
