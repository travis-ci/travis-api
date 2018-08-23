module Travis::API::V3
  class Renderer::Preference < ModelRenderer
    type :preference
    representation :standard, :name, :value
    representation :minimal, *representations[:standard]

    def href
      Renderer.href(:preference,
        :"preference.name" => name,
        :"script_name" => script_name
      )
    end
  end
end
