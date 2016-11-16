module Travis::Api::App::Responders
  class Image < Base
    def format
      'png'
    end

    def set_headers
      headers['Pragma'] = "no-cache"
      headers['Expires'] = Time.now.utc.httpdate
      headers['Content-Disposition'] = %(inline; filename="#{File.basename(filename)}")
    end

    instrument_method
    def apply
      set_headers
      send_file(filename, type: :png, last_modified: last_modified)
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

  end
end
