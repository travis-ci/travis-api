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
        os, *rest               = agent.application.comment
        ruby, rubygems, command = "unknown", "unknown", nil

        rest.each do |comment|
          case comment
          when /^Ruby (\d\.\d.\d)/ then ruby     = $1
          when /^RubyGems (.+)$/   then rubygems = $1
          when /^command (.+)$/    then command  = $1
          end
        end

        # "Ubuntu 12.04 like Linux" => "linux.ubuntu.12.04"
        if os =~ /^(.+) (\S+) like (\S+)$/
          os = "#{$3}.#{$1}.#{$2[/\d+\.\d+/]}"
        end

        if command
          mark(:cli, version: agent.version, ruby: ruby, rubygems: rubygems, command: command, os: os)
        else
          # only track ruby version and library version for non-cli usage
          mark(:script, :ruby, :travis, version: agent.version, ruby: ruby)
        end
      end

      def mark_unknown
        logger.warn "[user-agent-tracker] Unknown User-Agent: %p" % request.user_agent
        mark(:unknown)
      end

      def track_key(string)
        string.to_s.downcase.gsub(/[^a-z0-9\-\.]+/, '_')
      end

      def mark(*keys)
        key = "api.user_agent"
        keys.each do |subkey|
          if subkey.is_a? Hash
            subkey.each_pair { |k, v| ::Metriks.meter("#{key}.#{track_key(k)}.#{track_key(v)}").mark }
          else
            ::Metriks.meter(key << "." << track_key(subkey)).mark
          end
        end
      end
    end
  end
end
