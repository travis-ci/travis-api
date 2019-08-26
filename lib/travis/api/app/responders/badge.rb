module Travis::Api::App::Responders
  class Badge < Image
    def format
      'svg'
    end

    def apply
      set_headers
      if proxy_to_org?
        proxy_to_org
      elsif proxy_to_com?
        proxy_to_com
      else
        send_file(filename, type: :svg, last_modified: last_modified)
      end
    end

    def content_type
      "image/svg+xml"
    end

    def filename
      "#{root}/public/images/result/#{result}.svg"
    end
  end
end
