module Travis::API::V3
  module Renderer::InsightsSandboxPlugins
    extend self

    AVAILABLE_ATTRIBUTES = [:plugins, :in_progress, :no_plugins]

    def available_attributes
      AVAILABLE_ATTRIBUTES
    end

    def render(object, **)
      {
        '@type': 'insights_sandbox_plugins'.freeze,
        plugins: object.fetch('plugins', []),
        in_progress: object.fetch('in_progress', false),
        no_plugins: object.fetch('no_plugins', false)
      }
    end
  end
end
