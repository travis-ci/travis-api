require 'travis/api/app'

class Travis::Api::App
  module StackInstrumentation
    class Middleware
      def initialize(app, title = nil)
        @app   = app
        @title = title || "Rack: use #{app.class.name}"
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

    def use(*)
      super(Middleware)
      super
    end

    def run(app)
      super Middleware.new(app, "Rack: run %p" % app.class)
    end

    def map(path, &block)
      super(path) do
        use(Middleware, "Rack: map %p" % path)
        extend StackInstrumentation
        instance_eval(&block)
      end
    end
  end
end
