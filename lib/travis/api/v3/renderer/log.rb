require 'travis/api/v3/log_token'

module Travis::API::V3
  class Renderer::Log < ModelRenderer
    def self.render(model, representation = :standard, **options)
      return super unless options[:accept] == 'text/plain'.freeze
      model.content
    end

    def render(representation)
      result = super

      raw_log_href = "#{href}.txt"
      if raw_log_href !~ /^\/v3/
        raw_log_href = "/v3#{raw_log_href}"
      end
      if model.repository_private?
        token = LogToken.create(model.job)
        raw_log_href += "?log.token=#{token}"
      end
      result['@raw_log_href'] = raw_log_href

      result
    end

    representation(:minimal, :id)
    representation(:standard, *representations[:minimal], :content, :log_parts)
  end
end
