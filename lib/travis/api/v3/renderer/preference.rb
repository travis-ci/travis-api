module Travis::API::V3
  class Renderer::Preference < ModelRenderer
    type :preference
    representation :standard, :name, :value
    representation :minimal, *representations[:standard]

    # TODO: I couldn't make the framework generate the URL so I'm hardcoding it :_(
    def href
      case model.parent
      when Models::User
        "/v3/preference/#{name}"
      when Models::Organization
        "/v3/org/#{model.parent.id}/preference/#{name}"
        # or maybe `super` ??
      end
    end
  end
end
