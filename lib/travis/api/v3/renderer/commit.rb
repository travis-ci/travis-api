require 'travis/api/v3/renderer/model_renderer'

module Travis::API::V3
  class Renderer::Commit < Renderer::ModelRenderer
    representation(:minimal,  :id, :sha, :ref, :message, :compare_url, :committed_at)
    representation(:standard, *representations[:minimal], :committer, :author)

    def sha
      model.commit
    end

    def committer
      user_data(model.committer_name, model.committer_email)
    end

    def author
      user_data(model.author_name, model.author_email)
    end

    private

    def user_data(name, email)
      # query(:user).find_by_email(email) <= this triggers an N+1 query
      {
        #:@type      => 'user'.freeze,
        :name       => name,
        :avatar_url => Renderer::AvatarURL.avatar_url(email)
      }
    end
  end
end
