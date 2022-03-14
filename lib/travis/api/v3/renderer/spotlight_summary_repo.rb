module Travis::API::V3
  class Renderer::SpotlightSummaryRepo < ModelRenderer
    representation :standard, :repo_id, :repo_name
    representation :minimal, :repo_id, :repo_name
  end
end
