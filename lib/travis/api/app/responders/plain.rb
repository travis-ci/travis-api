module Travis::Api::App::Responders
  class Plain < Base
    def format
      'txt'
    end

    def apply?
      # make sure that we don't leak anything by processing only Log
      # instances here. I don't want to create entire new API builder just
      # for log's content for now.
      #
      # TODO: think how to handle other formats correctly
      super && resource.is_a?(Log)
    end

    def apply
      filename    = resource.id
      disposition = params[:attachment] ? 'attachment' : 'inline'

      headers['Content-Disposition'] = %(#{disposition}; filename="#{filename}")

      endpoint.content_type 'text/plain'
      halt(params[:deansi] ? clear_ansi(resource.content) : resource.content)
    end

    private

      def clear_ansi(content)
        content.gsub(/\r\r/, "\r")
               .gsub(/^.*\r(?!$)/, '')
               .gsub(/\x1b(\[|\(|\))[;?0-9]*[0-9A-Za-z]/m, '')
      end
  end
end
