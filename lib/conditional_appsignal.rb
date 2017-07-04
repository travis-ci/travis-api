module ConditionalAppsignal
  module DummyMixin
    def self.included(object)
      object.extend(self)
      super
    end

    def instrument_method(*)
    end
  end

  extend self

  def enabled?
    authenticated? and lucky_dyno?
  end

  def authenticated?
    ENV['APPSIGNAL_AUTHENTICATION'.freeze]
  end

  def lucky_dyno?
    @lucky_dyno = detect_lucy_dyno unless instance_variable_defined? :@lucky_dyno
    @lucky_dyno
  end

  def detect_lucy_dyno
    unless ENV['DYNO'.freeze]
      warn "[ConditionalAppsignal] $DYNO not set, skipping lucky dyno check and enabling Appsignal"
      return true
    end

    if ENV['APPSIGNAL_ENABLED'.freeze] == 'true'
      warn "[ConditionalAppsignal] enabling Appsignal on all dynos"
      return true
    end

    if ENV['APPSIGNAL_ENABLED_FOR_DYNOS'.freeze] && ENV['APPSIGNAL_ENABLED_FOR_DYNOS'.freeze].split(' ').include?(ENV['DYNO'.freeze])
      warn "[ConditionalAppsignal] lucky dyno, enabling Appsignal"
      return true
    end

    warn "[ConditionalAppsignal] not a lucky dyno, disabling Appsignal"
    false
  end

  if enabled?
    require 'appsignal'
    Mixin = Appsignal::Helpers
  else
    Mixin = DummyMixin
  end
end
