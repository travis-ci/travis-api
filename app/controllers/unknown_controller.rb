class UnknownController < ApplicationController
  def canonical_route
    redirect_to "/?q=#{params['other']}"
  end

  def repository
    repository_id = Repository.by_slug("#{params['owner']}/#{params['repo']}").first&.id
    redirect_to repository_id ? "/repositories/#{repository_id}" : :not_found
  end
end