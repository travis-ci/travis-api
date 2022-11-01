require 'travis/api/v3/log_token'

module Travis::API::V3
  class Renderer::Log < ModelRenderer
    def self.render(model, representation = :standard, **options)
      return super unless options[:accept] == 'text/plain'.freeze
      model.content
    end

    # Override the inherited Rederer.href for Enterprise to have no script_name since that will always resolve to
    # /api in Enterprise, as Enterprise's API lives in a path not a subdomain, and will throw off the manipulations
    # we do in the render method we do in this class.
    def href
      if Travis.config.enterprise
        Renderer.href(self.class.type, model.attributes, script_name: '')
      else
        super
      end
    end

    def render(representation)
      result = super

      raw_log_href = "#{href}.txt"
      if raw_log_href !~ /^\/v3/
        raw_log_href = "/v3#{raw_log_href}"
      end
      if enterprise? || model.repository_private? || model.repository.user_settings.job_log_access_based_limit
        token = LogToken.create(model.job, access_control&.user&.id)
        raw_log_href += "?log.token=#{token}"
      end
      result['@raw_log_href'] = raw_log_href

      result
    end

    private def enterprise?
      !!Travis.config.enterprise
    end

    representation(:minimal, :id)
    representation(:standard, *representations[:minimal], :content, :log_parts)
  end
end
