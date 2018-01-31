require 'auth/helpers/faraday'
require 'auth/helpers/rack_test'

RSpec::Matchers.define :auth do |expected|
  match do |actual|
    status?(expected, actual) &&
      body?(expected, actual) &&
      type?(expected, actual) &&
      image?(expected, actual)
  end

  def status?(expected, actual)
    case expected[:status]
    when Array
      expected[:status].include?(actual[:status])
    else
      actual[:status] == expected[:status]
    end
  end

  def body?(expected, actual)
    return true if !expected.key?(:empty) || ENV['AUTH_TESTS_ADAPTER'] == 'faraday'
    body = JSON.parse(actual[:body]) rescue actual[:body]
    body = compact(body)
    expected[:empty] ? body.blank? : body.present?
  end

  def type?(expected, actual)
    return true if !expected.key?(:type)
    type = actual[:headers]['Content-Type']
    case expected[:type]
    when :img
      type.include?('image/png') || type.include?('image/svg')
    when :json
      type.include?('application/json')
    when :xml
      type.include?('application/xml')
    when :atom
      type.include?('application/atom')
    end
  end

  def image?(expected, actual)
    return true unless expected.key?(:image)
    image = /#{expected[:image]}\.(png|svg)/
    actual[:headers]['Content-Disposition'] =~ image
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
      c.before { Travis.config[:host] = 'example.com' }
      c.before { |c| set_private(c.metadata[:repo] == :private) }
      c.before { |c| set_mode(c.metadata[:mode]) }
      c.after { Travis.config[:host] = 'travis-ci.org' }
      c.after { Travis.config[:public_mode] = true }
      c.subject { |a| send(a.description) }
    end

    extend Forwardable

    def_delegators :adapter, :set_mode, :set_private, :authenticated,
      :with_permission, :without_permission, :invalid_token, :unauthenticated

    def adapter
      @adapter ||= self.class.const_get(ENV.fetch('AUTH_TESTS_ADAPTER', 'rack_test').camelize).new(self)
    end
  end
end
