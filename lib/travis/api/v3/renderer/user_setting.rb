module Travis::API::V3
  class Renderer::UserSetting < ModelRenderer
    type :setting
    representation :standard, :name, :value
    representation :minimal, *representations[:standard]

    def href
      Renderer.href(:user_setting,
        :"repository.id" => model.repository_id,
        :"setting.name" => name,
        :"script_name" => script_name
      )
    end
  end
end
