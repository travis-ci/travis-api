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
    return @lucky_dyno if instance_variable_defined? :@lucky_dyno
    if ENV['DYNO'.freeze] and ENV['DYNO_COUNT'.freeze]
      dyno        = Integer ENV['DYNO'.freeze][/\d+/]
      @lucky_dyno = dyno % 5 == 1
    else
      @lucky_dyno = true
    end
  end

  if enabled?
    require 'skylight'
    Mixin = Skylight::Helpers
  else
    Mixin = DummyMixin
  end
end
