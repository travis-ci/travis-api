class UnknownController < ApplicationController
  def build
    redirect_to "/builds/#{params['id']}"
  end

  def canonical_route
    valid_login = User.find_by(login: params['other']).present? || Organization.find_by(login: params['other']).present?
    redirect_to valid_login ? "/?q=#{params['other']}" : :not_found
  end

  def job
    redirect_to "/jobs/#{params['id']}"
  end

  def repository
    repository = Repository.by_slug("#{params['owner']}/#{params['repo']}").first
    redirect_to repository ? "/repositories/#{repository.id}" : :not_found
  end
end
