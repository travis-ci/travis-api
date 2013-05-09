require 'travis/api/app'

class Travis::Api::App
  class Middleware
    class Rewrite < Middleware
      FORMAT      = %r(\.(json|xml|png|txt)$)
      V1_REPO_URL = %r(^(/[^/]+/[^/]+(?:/builds(?:/[\d]+)?|/cc)?)$)

      helpers :accept

      set(:setup) { ActiveRecord::Base.logger = Travis.logger }

      before do
        extract_format
        rewrite_v1_repo_segment if v1? || xml?
        rewrite_v1_named_repo_image_path if png?
      end

      after do
        redirect_v1_named_repo_path if (v1? || xml?) && not_found?
      end

      private

        def extract_format
          env['PATH_INFO'].sub!(FORMAT, '')
          env['travis.format_from_path'] = $1
          env['travis.format'] = $1 || accept_format
        end

        def rewrite_v1_repo_segment
          env['PATH_INFO'].sub!(%r(^/repositories), '/repos')
        end

        def rewrite_v1_named_repo_image_path
          env['PATH_INFO'].sub!(V1_REPO_URL) { "/repos#{$1}" }
        end

        def redirect_v1_named_repo_path
          force_redirect("/repositories#{$1}.#{env['travis.format']}") if request.path =~ V1_REPO_URL
        end

        def force_redirect(path)
          path += "?#{request.query_string}" unless request.query_string.empty?
          response.body = ''
          response['Content-Length'] = '0'
          response['Content-Type'] = ''
          redirect(path)
        end

        def png?
          env['travis.format'] == 'png'
        end

        def xml?
          env['travis.format'] == 'xml'
        end

        def v1?
          accept_version == 'v1'
        end
    end
  end
end

