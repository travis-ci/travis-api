module Travis::API::V3
  class Renderer::UserSetting < Renderer::ModelRenderer
    representation :standard, :name, :value

    def href
      Renderer.href(:user_setting,
        :"repository.id" => model.repository_id,
        :"setting.name" => name,
        :"script_name" => script_name
      )
    end
  end
end
