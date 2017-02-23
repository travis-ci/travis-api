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
      super && (resource.is_a?(Log) || resource.is_a?(RemoteLog) || resource.is_a?(String))
    end

    instrument_method
    def apply
      super

      if resource.is_a?(Log) || resource.is_a?(RemoteLog)
        filename    = resource.id
        disposition = params[:attachment] ? 'attachment' : 'inline'

        headers['Content-Disposition'] = %(#{disposition}; filename="#{filename}")

        params[:deansi] ? clear_ansi(resource.content) : resource.content
      else
        resource
      end
    end

    private

      def content_type
        'text/plain'
      end

      def clear_ansi(content)
        content.gsub(/\r\r/, "\r")
               .gsub(/^.*\r(?!$)/, '')
               .gsub(/\x1b(\[|\(|\))[;?0-9]*[0-9A-Za-z]/m, '')
      end
  end
end
