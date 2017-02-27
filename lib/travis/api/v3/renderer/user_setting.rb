module Travis::API::V3
  class Renderer::UserSetting < Renderer::ModelRenderer
    representation :standard, :name, :value
    representation :minimal, *representations[:standard]

    def href
      Renderer.href(:user_setting,
        :"repository.id" => model.repository_id,
        :"user_setting.name" => name,
        :"script_name" => script_name
      )
    end
  end
end
