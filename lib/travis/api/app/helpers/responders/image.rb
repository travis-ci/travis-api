module Travis::Api::App::Helpers::Responders
  class Image < Base
    NAMES = { nil => 'unknown', 0 => 'passing', 1 => 'failing' }

    def apply?
      options[:format] == 'png'
    end

    def apply
      headers['Expires'] = Time.now.utc.httpdate
      halt send_file(filename(resource), type: :png, disposition: :inline)
    end

    private

      def filename(resource)
        "#{root}/public/images/result/#{result(resource)}.png"
      end

      def result(resource)
        NAMES[resource.try(:last_build_result_on, branch: params[:branch])]
      end

      def root
        File.expand_path('.') # TODO wat.
      end
  end
end
