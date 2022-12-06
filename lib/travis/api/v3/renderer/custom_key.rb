module Travis::API::V3
  class Renderer::CustomKey < ModelRenderer
    representation :standard, :id, :name, :description, :public_key, :fingerprint, :added_by_login, :created_at
    representation :minimal, *representations[:standard]

    def added_by_login
      model.added_by.nil? ? '' : User.find(model.added_by).login
    end
  end
end
