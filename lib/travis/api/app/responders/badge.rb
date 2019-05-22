module Travis::Api::App::Responders
  class Badge < Image
    def format
      'svg'
    end

    def apply
      if redirect_to_com?
        redirect_to_com
      else
        set_headers
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
