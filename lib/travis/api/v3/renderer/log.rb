require 'travis/api/v3/log_token'

module Travis::API::V3
  class Renderer::Log < ModelRenderer
    def self.render(model, representation = :standard, **options)
      return super unless options[:accept] == 'text/plain'.freeze
      model.content
    end

    def render(representation)
      result = super

      raw_url = "#{href}.txt"
      if raw_url !~ /^\/v3/
        raw_url = "/v3#{raw_url}"
      end
      if model.repository_private?
        token = LogToken.create(model.job)
        raw_url += "?log.token=#{token}"
      end
      result['@raw_url'] = raw_url

      result
    end

    representation(:minimal, :id)
    representation(:standard, *representations[:minimal], :content, :log_parts)
  end
end
