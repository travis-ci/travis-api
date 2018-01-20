RSpec::Matchers.define :auth do |expected|
  match do |actual|
    status?(expected, actual) && body?(expected, actual)
  end

  def status?(expected, actual)
    actual[:status] == expected[:status]
  end

  def body?(expected, actual)
    return true unless expected.key?(:empty)
    body = JSON.parse(last_response.body) rescue last_response.body
    body = compact(body)
    expected[:empty] ? body.blank? : body.present?
  end

  def compact(obj)
    case obj
    when Array
      obj.select(&:present?)
    when Hash
      obj.select { |key, value| value.present? }
    else
      obj
    end
  end
end

module Support
  module AuthHelpers
    def self.included(c)
      c.after { Travis.config[:public_mode] = false }
      c.subject { |a| send(a.description) }
    end

    def with_permission
      Permission.create!(user_id: user.id, repository_id: repo.id, admin: true, push: true)
      request_by_description create_token
    end

    def authenticated
      # TODO remove ... but something's weird about some repo endpoints when
      # results are empty
      if respond_to?(:repo)
        Permission.create!(user_id: user.id, repository_id: repo.id, admin: true, push: true)
      end
      request_by_description create_token
    end

    def without_permission
      request_by_description create_token
    end

    def invalid_token
      request_by_description '12345'
    end

    def unauthenticated
      request_by_description nil
    end

    def create_token
      Travis::Api::App::AccessToken.create(user: user, app_id: -1).token
    end

    def request_by_description(token)
      method, path = RSpec.current_example.example_group.description.split(' ')
      path  = interpolate(self, path)
      query = { access_token: token }
      send(method.downcase, path, query, headers_for_version)
      { status: last_response.status, body: last_response.body }
    end

    def headers_for_version
      # v1 is the default version according to /lib/travis/api/app/helpers/accept.rb
      case api_version
      when :v2
        { 'HTTP_ACCEPT' => 'application/vnd.travis-ci.2+json' }
      else
        {}
      end
    end

    def api_version
      RSpec.current_example.metadata[:api_version]
    end

    # assumes that, e.g. for `"%{repo.slug}"`, the rspec context responds to `repo`,
    # e.g. via `let(:repo)`, and `repo` responds to `slug`
    def interpolate(obj, str)
      str % Hash.new { |_, key| key.to_s.split('.').inject(obj) { |o, key| o.send(key) } }
    end
  end
end
