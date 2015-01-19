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
      warn "[ConditionalSkylight] $DYNO not set, skipping lucky dyno check"
      return true
    end

    unless ENV['DYNO_COUNT'.freeze]
      warn "[ConditionalSkylight] $DYNO_COUNT not set, skipping lucky dyno check"
      return true
    end

    dyno = Integer ENV['DYNO'.freeze][/\d+/]

    if dyno % 5 == 1
      warn "[ConditionalSkylight] lucky dyno, enabling Skylight"
      true
    else
      warn "[ConditionalSkylight] not a lucky dyno, disabling Skylight"
      false
    end
  end

  if enabled?
    require 'skylight'
    Mixin = Skylight::Helpers
  else
    Mixin = DummyMixin
  end
end
