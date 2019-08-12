module Travis::Api::App::Responders
  class Image < Base
    PROXY_USER_AGENT = 'API-badges-proxy'
    def format
      'png'
    end

    def set_headers
      headers['Pragma'] = "no-cache"
      headers['Expires'] = Time.now.utc.httpdate
      headers['Content-Disposition'] = %(inline; filename="#{File.basename(filename)}")
    end

    def apply
      if proxy_to_com?
        proxy_to_com
      else
        set_headers
        send_file(filename, type: :png, last_modified: last_modified)
      end
    end

    def apply?
      # :type_hint is returned by repos endpoint
      # so that we can return a 'unknown.png' image
      (super && resource.is_a?(Repository)) || (acceptable_format? && resource.nil? && options[:type_hint] == Repository)
    end

    private

      def content_type
        'image/png'
      end

      def filename
        "#{root}/public/images/result/#{result}.png"
      end

      def result
        if resource
          Repository::StatusImage.new(resource, params[:branch]).result
        else
          'unknown'
        end
      end

      def root
        File.expand_path('.')
      end

      def last_modified
        resource ? resource.last_build_finished_at : nil
      end

      def proxy_to_com?
        Travis.config.org? && ((resource.is_a?(Repository) && resource.migrated?) || resource.nil?) &&
          endpoint.env['HTTP_USER_AGENT'] != PROXY_USER_AGENT
      end

      def proxy_to_com
        uri = URI.parse(com_url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        request = request = Net::HTTP::Get.new uri
        request['Accept'] = content_type
        request['User-Agent'] = PROXY_USER_AGENT
        result = http.request request
        endpoint.status result.code
        endpoint.content_type content_type
        result.body
      end

      def com_url
        path = endpoint.request.path_info.sub(/^\/repo_status/, '')
        url = [Travis.config.api_com_url, path].join
        url = [url, endpoint.env['travis.format_from_path']].join('.') if endpoint.env['travis.format_from_path']
        url = [url, endpoint.request.query_string].join('?') if endpoint.request.query_string.present?
        url
      end
  end
end
