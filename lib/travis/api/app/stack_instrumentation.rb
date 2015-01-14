require 'travis/api/app'

class Travis::Api::App
  module StackInstrumentation
    class Middleware
      def initialize(app, title = nil)
        @app   = app
        @title = title || StackInstrumentation.title_for(app, :use)
      end

      def call(env)
        instrument { @app.call(env) }
      end

      def instrument(&block)
        return yield unless instrument?
        ::Skylight.instrument(title: @title, &block)
      end

      def instrument?
        defined? ::Skylight
      end
    end

    def self.title_for(verb, object)
      object &&=  case object
                  when ::Sinatra::Wrapper then object.settings.inspect
                  when Class, Module      then object.inspect
                  when String             then object
                  else object.class.inspect
                  end
      "Rack: #{verb} #{object}"
    end

    def use(*)
      super(Middleware)
      super
    end

    def run(app)
      super Middleware.new(app, StackInstrumentation.title_for(app, :run))
    end

    def map(path, &block)
      super(path) do
        use(Middleware, StackInstrumentation.title_for(path, :map))
        extend StackInstrumentation
        instance_eval(&block)
      end
    end
  end
end
