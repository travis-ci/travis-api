module Support
  module AuthHelpers
    module Shared
      def method
        example_group_description.split(' ').first.downcase
      end

      def path
        interpolate(self, example_group_description.split(' ')[1])
      end

      def query_token?
        !!query_token
      end

      def query_token
        path =~ /token=[^&]*(&|$)/ && $1
      end

      def accept_header
        ctx.respond_to?(:accept) ? ctx.accept : case api_version
        when :v1
          ''
        when :v2
          # 'application/vnd.travis-ci.2+json,text/vnd.travis-ci.2.1+plain'
          'application/json; version=2, text/plain; version=2'
        when :'v2.1'
          # 'application/vnd.travis-ci.2.1+json,text/vnd.travis-ci.2.1+plain'
          'application/json; version=2.1, text/plain; version=2.1'
        end
      end

      def api_version
        RSpec.current_example.metadata[:api_version]
      end

      def example_group_description
        RSpec.current_example.example_group.description
      end

      # assumes that, e.g. for `"%{repo.slug}"`, the rspec context responds to `repo`,
      # e.g. via `let(:repo)`, and `repo` responds to `slug`
      def interpolate(obj, str)
        str % Hash.new { |_, key| key.to_s.split('.').inject(obj) { |o, key| o.send(key) } }
      end
    end
  end
end
