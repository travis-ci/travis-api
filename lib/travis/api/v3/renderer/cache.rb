module Travis::API::V3
  class Renderer::Cache < Renderer::ModelRenderer
    representation(:minimal,  :repository_id, :size, :name, :branch, :last_modified)
    representation(:standard, *representations[:minimal], :repo)
    # 
    # def self.available_attributes
    #   [:branch, :name]
    # end

  end
end
