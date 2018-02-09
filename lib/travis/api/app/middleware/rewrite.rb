require 'travis/api/app'

class Travis::Api::App
  class Middleware
    class Rewrite < Middleware
      FORMAT      = %r(\.(json|xml|png|txt|atom|svg)$)
      V1_REPO_URL = %r(^(/[^/]+/[^/]+(?:/builds(?:/[\d]+)?|/cc)?)$)

      helpers :accept

      set(:setup) { ActiveRecord::Base.logger = Travis.logger }

      before do
        extract_format
        rewrite_v1_repo_segment if v1? && repos_path?
        rewrite_v1_named_repo_image_path if image?
        rewrite_repo_status_segment if rewrite_pre_v3?
        # p env['PATH_INFO']
      end

      after do
        redirect_v1_named_repo_path if redirect_v1_named_repo_path?
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

        def rewrite_repo_status_segment
          env['PATH_INFO'].sub!(%r(^/repos/), '/repo_status/')
        end

        def rewrite_v1_named_repo_image_path
          env['PATH_INFO'].sub!(V1_REPO_URL) { "/repos#{$1}" }
        end

        def redirect_v1_named_repo_path?
          not_found? && v1? && (image? || xml?) &&
            !repos_path? && !repo_status_path? &&
            request.path =~ V1_REPO_URL
        end

        def redirect_v1_named_repo_path
          force_redirect("/repos#{request.path}.#{env['travis.format']}")
        end

        def force_redirect(path)
          path += "?#{request.query_string}" unless request.query_string.empty?
          response.body = ''
          response['Content-Length'] = '0'
          response['Content-Type'] = ''
          redirect(path)
        end

        def rewrite_v1?
          v1? && repos_path? && (image? || xml? || atom?)
        end

        def rewrite_pre_v3?
          pre_v3? && repos_path? && (image? || xml? || atom?)
        end

        def repos_path?
          env['PATH_INFO'].start_with?('/repos')
        end

        def repo_status_path?
          env['PATH_INFO'].start_with?('/repo_status/')
        end

        def image?
          png? || svg?
        end

        def png?
          # accepts?('image/png')
          env['travis.format'] == 'png' || accept_headers.include?('image/png')
        end

        def svg?
          # accepts?('applciation/svg')
          env['travis.format'] == 'svg' || accept_headers.include?('image/svg')
        end

        def xml?
          env['travis.format'] == 'xml' || accept_headers.include?('application/xml')
        end

        def atom?
          env['travis.format'] == 'atom' || accept_headers.include?('application/atom')
        end

        PRE_V3 = %w(v1 v2 v2.1)

        def pre_v3?
          PRE_V3.include?(accept_version)
        end

        def v1?
          accept_version == 'v1'
        end

        def v2?
          accept_version == 'v2'
        end

        def accept_headers
          env['HTTP_ACCEPT'].to_s
        end

        def routes_to?(const)
          const.routes['GET'].any? { |r| r[0].match(env['PATH_INFO']) }
        end
    end
  end
end
