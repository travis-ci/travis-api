require 'travis/api/app'
require 'useragent'

class Travis::Api::App
  class Middleware
    class UserAgentTracker < Middleware
      WEB_BROWSERS = [
        "Internet Explorer",
        "Webkit", "Chrome", "Safari", "Android",
        "Firefox", "Camino", "Iceweasel", "Seamonkey", "Android",
        "Opera", "Mozilla"
      ]

      before(agent: /^$/) do
        ::Metriks.meter("api.user_agent.missing").mark
        halt(400, "error" => "missing User-Agent header") if Travis::Features.feature_active?(:require_user_agent)
      end

      before(agent: /^.+$/) do
        agent = UserAgent.parse(request.user_agent)
        case agent.browser
        when *WEB_BROWSERS                   then mark_browser
        when "curl", "Wget"                  then mark(:console, agent.browser)
        when "travis-api-wrapper"            then mark(:script, :node_js, agent.browser)
        when "TravisPy"                      then mark(:script, :python,  agent.browser)
        when "Ruby", "PHP", "Perl", "Python" then mark(:script, agent.browser, :vanilla)
        when "Faraday"                       then mark(:script, :ruby, :vanilla)
        when "Travis"                        then mark_travis(agent)
        else mark_unknown
        end
      end

      def mark_browser
        # allows a JavaScript Client to set X-User-Agent, for instance to "travis-web" in travis-web
        x_agent = UserAgent.parse(env['HTTP_X_USER_AGENT'] || 'unknown').browser
        mark(:browser, x_agent)
      end

      def mark_travis(agent)
        command = agent.application.comment.detect { |c| c.start_with? "command " } if agent.application.comment

        if command
          mark(:cli, :version, agent.version)
          mark(:cli, command.sub(' ', '.'))
        else
          # only track ruby version and library version for non-cli usage
          mark(:script, :ruby, :travis, :version, agent.version)
        end
      end

      def mark_unknown
        logger.warn "[user-agent-tracker] Unknown User-Agent: %p" % request.user_agent
        mark(:unknown)
      end

      def mark(*keys)
        key = "api.user_agent." << keys.map { |k| k.to_s.downcase.gsub(/[^a-z0-9\-\.]+/, '_') }.join('.')
        ::Metriks.meter(key).mark
      end
    end
  end
end
