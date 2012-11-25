module Travis::Api::App::Responders
  class Image < Base
    def apply?
      options[:format] == 'png'
    end

    def apply
      headers['Expires'] = Time.now.utc.httpdate
      halt send_file(filename, type: :png, disposition: :inline)
    end

    private

      def filename
        "#{root}/public/images/result/#{result}.png"
      end

      def result
        Repository::StatusImage.new(resource, params[:branch]).result
      end

      def root
        File.expand_path('.') # TODO wat.
      end
  end
end
