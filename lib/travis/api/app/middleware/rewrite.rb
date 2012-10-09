require 'travis/api/app'

class Travis::Api::App
  class Middleware
    class Rewrite < Middleware
      V1_REPO_URL = %r(^(/[^/]+/[^/]+(?:/builds(?:/[\d]+)?|/cc\.xml)?)$)

      set(:setup) { ActiveRecord::Base.logger = Travis.logger }

      after do
p not_found?
        force_redirect("/repositories#{$1}") if response.status == 404 && version == 'v1' && request.path =~ V1_REPO_URL
      end

      private

        def force_redirect(path)
          response.body = ''
          response['Content-Length'] = '0'
          response['Content-Type'] = ''
          redirect(path)
        end

        def version
          API.version(request.accept.join)
        end
    end
  end
end

