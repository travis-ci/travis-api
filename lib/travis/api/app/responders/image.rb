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

    def apply
      set_headers
      send_file(filename, type: :png, last_modified: last_modified)
    end

    def apply?
      super && resource.is_a?(Repository)
    end

    private

      def content_type
        'image/png'
      end

      def filename
        "#{root}/public/images/result/#{result}.png"
      end

      def result
        Repository::StatusImage.new(resource, params[:branch]).result
      end

      def root
        File.expand_path('.')
      end

      def last_modified
        resource ? resource.last_build_finished_at : nil
      end

  end
end
