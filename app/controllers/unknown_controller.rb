class UnknownController < ApplicationController
  def canonical_route
    valid_login = User.find_by(login: params['other']).present? || Organization.find_by(login: params['other']).present?
    redirect_to valid_login ? "/?q=#{params['other']}" : :not_found
  end

  def repository
    repository = Repository.by_slug("#{params['owner']}/#{params['repo']}").first
    redirect_to repository ? "/repositories/#{repository.id}" : :not_found
  end
end
