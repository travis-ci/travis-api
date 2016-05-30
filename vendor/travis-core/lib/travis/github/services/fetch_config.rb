require 'gh'
require 'yaml'
require 'active_support/core_ext/class/attribute'
require 'travis/support/logging'
require 'travis/support/instrumentation'
require 'travis/services/base'

module Travis
  module Github
    module Services
      # encapsulates fetching a .travis.yml from a given commit's config_url
      class FetchConfig < Travis::Services::Base
        include Logging
        extend Instrumentation

        register :github_fetch_config

        def run
          config = retrying(3) { filter(parse(fetch)) }
          config || Travis.logger.warn("[request:fetch_config] Empty config for request id=#{request.id} config_url=#{config_url.inspect}")
        rescue GH::Error => e
          if e.info[:response_status] == 404
            { '.result' => 'not_found' }
          else
            { '.result' => 'server_error' }
          end
        end
        instrument :run

        def request
          params[:request]
        end

        def config_url
          request.config_url
        end

        private

          def fetch
            content = GH[config_url]['content']
            Travis.logger.warn("[request:fetch_config] Empty content for #{config_url}") if content.nil?
            content = content.to_s.unpack('m').first
            Travis.logger.warn("[request:fetch_config] Empty unpacked content for #{config_url}, content was #{content.inspect}") if content.nil?
            nbsp = "\xC2\xA0".force_encoding("binary")
            content = content.gsub(/^(#{nbsp})+/) { |match| match.gsub(nbsp, " ") }

            content
          end

          def parse(yaml)
            YAML.load(yaml).merge('.result' => 'configured')
          rescue StandardError, Psych::SyntaxError => e
            error "[request:fetch_config] Error parsing .travis.yml for #{config_url}: #{e.message}"
            {
              '.result' => 'parse_error',
              '.result_message' => e.is_a?(Psych::SyntaxError) ? e.message.split(": ").last : e.message
            }
          end

          def filter(config)
            unless Travis::Features.active?(:template_selection, request.repository)
              config = config.to_h.except('dist').except('group')
            end

            config
          end

          def retrying(times)
            count, result = 0, nil
            until result || count > times
              result = yield
              count += 1
              Travis.logger.warn("[request:fetch_config] Retrying to fetch config for #{config_url}") unless result
            end
            result
          end

          class Instrument < Notification::Instrument
            def run_completed
              # TODO exctract something like Url.strip_secrets
              config_url = target.config_url.gsub(/(token|secret)=\w*/) { "#{$1}=[secure]" }
              publish(msg: "#{config_url}", url: config_url, result: result)
            end
          end
          Instrument.attach_to(self)
      end
    end
  end
end
