class CustomKeysController < ApplicationController
  def delete
    custom_key = CustomKey.find_by(id: params[:id])

    custom_key.destroy
    ::Audit.create!(
      owner: current_user,
      change_source: 'admin-v2',
      source: custom_key,
      source_changes: {
        action: 'delete',
        name: custom_key.name,
        owner_type: custom_key.owner_type,
        owner_id: custom_key.owner_id,
        fingerprint: custom_key.fingerprint
      }
    )
    flash[:notice] = 'SSH key successfully deleted.'

    if custom_key.owner_type == 'User'
      redirect_to user_path(custom_key.owner_id)
    else custom_key.owner_type == 'Organization'
      redirect_to organization_path(custom_key.owner_id)
    end
  end
end
