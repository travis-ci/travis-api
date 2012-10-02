require 'travis/api/app'
require 'cgi'

module Travis::Api::App::Helpers
  module ResultImage
    RESULT_NAMES = { nil => 'unknown', 0 => 'passing', 1 => 'failing' }

    def result_image(resource)
      headers['Expires'] = CGI.rfc1123_date(Time.now.utc)
      filename = filename(resource)
      env['travis.sending-file'] = filename
      send_file filename, type: :png, disposition: :inline
    end

    protected

      def filename(resource)
        root = File.expand_path("#{settings.root}/../../../../../") # TODO wat.
        "#{root}/public/images/result/#{result(resource)}.png"
      end

      def result(resource)
        RESULT_NAMES[resource.try(:last_build_result_on, branch: params[:branch])]
      end
  end
end

