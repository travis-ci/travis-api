module Travis::Api::App::Responders
  class Image < Base
    def format
      'png'
    end

    def apply
      headers['Pragma'] = "no-cache"
      headers['Expires'] = Time.now.utc.httpdate
      headers['Content-Disposition'] = %(inline; filename="#{File.basename(filename)}")
      halt send_file(filename, type: :png)
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
