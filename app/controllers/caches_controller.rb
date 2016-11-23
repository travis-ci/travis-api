class CachesController < ApplicationController
  def delete
    @repository = Repository.find_by(id: params[:id])

    response = Services::Repository::Caches::Delete.new(@repository).call(params[:branch])

    if response.success?
      flash[:notice] = "The '#{params[:branch]}' cache for #{@repository.slug} was successfully deleted."
      Services::AuditTrail::DeleteBranchCache.new(current_user, @repository, params[:branch]).call
    else
      flash[:error]  = "Error: #{response.headers[:status]}"
    end

    redirect_to repository_path(@repository, anchor: 'caches')
  end

  def delete_all
    @repository = Repository.find_by(id: params[:id])

    response = Services::Repository::Caches::Delete.new(@repository).call

    if response.success?
      flash[:notice] = "Caches for #{@repository.slug} were successfully deleted."
      Services::AuditTrail::DeleteAllCaches.new(current_user, @repository).call
    else
      flash[:error]  = "Error: #{response.headers[:status]}"
    end

    redirect_to repository_path(@repository, anchor: 'caches')
  end
end
