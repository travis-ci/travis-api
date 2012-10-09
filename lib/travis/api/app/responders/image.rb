module Travis::Api::App::Responders
  class Image < Base
    NAMES = { nil => 'unknown', 0 => 'passing', 1 => 'failing' }

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
        NAMES[resource.try(:last_build_result_on, branch: params[:branch])]
      end

      def root
        File.expand_path('.') # TODO wat.
      end
  end
end
