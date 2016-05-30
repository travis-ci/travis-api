require 'action_mailer'
require 'i18n'

module Travis
  module Mailer
    class << self
      def config
        config = Travis.config.smtp
        config ? config.to_h : {}
      end

      def setup
        if config.present?
          mailer = ActionMailer::Base
          mailer[:delivery_method] = :smtp
          mailer[:smtp_settings] = config
          @setup = true
        end
      end

      def setup?
        !!@setup
      end
    end
  end
end
