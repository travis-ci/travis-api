class CachesController < ApplicationController
  def delete
    @repository = Repository.find_by(id: params[:id])

    response = Services::Repository::Caches::Delete.new(@repository.id).call(params[:branch])

    if response.success?
      message = "Cache on branch '#{branch}' successfully deleted."
      Services::AuditTrail::DeleteBranchCache.new(current_user, @repository, params[:branch]).call
    else
      message = "Error: #{response.headers[:status]}"
    end

    respond_to do |format|
      format.html do
        if response.success?
          flash[:notice] = message
        else
          flash[:error] = message
        end

        redirect_to repository_path(@repository, anchor: 'caches')
      end

      format.json do
        if response.success?
          render json: {"success": true, "message": message}
        else
          render json: {"success": false, "message": message}
        end
      end
    end
  end

  def delete_all
    @repository = Repository.find_by(id: params[:id])

    response = Services::Repository::Caches::Delete.new(@repository.id).call(nil)

    if response.success?
      message = "Caches for #{@repository.slug} successfully deleted."
      Services::AuditTrail::DeleteAllCaches.new(current_user, @repository).call
    else
      message = "Error: #{response.headers[:status]}"
    end

    respond_to do |format|
      format.html do
        if response.success?
          flash[:notice] = message
        else
          flash[:error] = message
        end

        redirect_to repository_path(@repository, anchor: 'caches')
      end

      format.json do
        if response.success?
          render json: {"success": true, "message": message}
        else
          render json: {"success": false, "message": message}
        end
      end
    end
  end
end
