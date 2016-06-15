module Travis
  module Testing
    module Stubs
      module Stub
        def stub(name, attributes)
          Object.new.tap do |object|
            meta_class = (class << object; self; end)
            class_stub = stub_class(name.camelize)

            attributes.each do |name, value|
              meta_class.send(:define_method, name) { |*| value }
            end

            meta_class.send(:define_method, :class) do
              class_stub
            end

            meta_class.send(:define_method, :is_a?) do |const|
              const.name.to_s == name.to_s.camelize
            end

            meta_class.send(:define_method, :inspect) do
              attrs = attributes.map { |name, value| [name, value.inspect].join('=') }.join(' ')
              "#<#{name.camelize}:#{object.object_id} #{attrs}>"
            end
          end
        end

        # TODO needs to take care of nested namespaces, so we can pass 'job/test'
        def stub_class(name)
          if const_defined?(*method(:const_defined?).arity == 1 ? [name] : [name, false])
            const_get(name)
          else
            Class.new.tap do |const|
              const_set(name, const)
              meta_class = (class << const; self; end)
              meta_class.send(:define_method, :name) { name }
              meta_class.send(:define_method, :inspect) { name }
            end
          end
        end
      end
    end
  end
end
