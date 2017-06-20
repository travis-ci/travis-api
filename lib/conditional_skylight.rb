module ConditionalSkylight
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
    ENV['SKYLIGHT_AUTHENTICATION'.freeze]
  end

  def lucky_dyno?
    @lucky_dyno = detect_lucy_dyno unless instance_variable_defined? :@lucky_dyno
    @lucky_dyno
  end

  def detect_lucy_dyno
    unless ENV['DYNO'.freeze]
      warn "[ConditionalSkylight] $DYNO not set, skipping lucky dyno check and enabling Skylight"
      return true
    end

    if ENV['SKYLIGHT_ENABLED'.freeze] == 'true'
      warn "[ConditionalSkylight] enabling Skylight on all dynos"
      return true
    end

    if ENV['SKYLIGHT_ENABLED_FOR_DYNOS'.freeze] && ENV['SKYLIGHT_ENABLED_FOR_DYNOS'.freeze].split(' ').include?(ENV['DYNO'.freeze])
      warn "[ConditionalSkylight] lucky dyno, enabling Skylight"
      return true
    end

    warn "[ConditionalSkylight] not a lucky dyno, disabling Skylight"
    false
  end

  if enabled?
    require 'skylight'
    Mixin = Skylight::Helpers
  else
    Mixin = DummyMixin
  end
end
