module Travis::Api::App::Responders
  class Plain < Base
    def apply?
      # make sure that we don't leak anything by processing only Artifact::Log
      # instances here. I don't want to create entire new API builder just
      # for log's content for now.
      #
      # TODO: think how to handle other formats correctly
      options[:format] == 'txt' && resource.is_a?(Artifact::Log)
    end

    def apply
      filename    = resource.id
      disposition = params[:attachment] ? 'attachment' : 'inline'

      headers['Content-Disposition'] = %(#{disposition}; filename="#{filename}")

      endpoint.content_type 'text/plain'
      halt resource.content
    end
  end
end
