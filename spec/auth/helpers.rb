require 'auth/helpers/faraday'
require 'auth/helpers/rack_test'
require 'active_support/core_ext/hash'

require 'active_support/all'

RSpec.shared_context 'cache setup' do
  include Support::S3
  before { Travis.config.cache_options = { s3: { bucket_name: '' , access_key_id: '', secret_access_key: ''} } }
  before { s3_bucket << "#{repo.github_id}/master/cache--example1.tbz" }
end

RSpec::Matchers.define :auth do |expected|
  match do |actual|
    fail 'status 200 with no :type given' if expected[:status] == 200 && !expected.key?(:type)
    fail 'status 200 with no :empty key given' if expected[:status] == 200 && !expected.key?(:empty) && expected[:type] != :img
    status?(expected, actual) &&
      body?(expected, actual) &&
      type?(expected, actual) &&
      file?(expected, actual)
  end

  def status?(expected, actual)
    Array(expected[:status]).include?(actual[:status])
  end

  def body?(expected, actual)
    return true if !expected.key?(:empty) || redirect?(actual[:status])
    # return true if ENV['AUTH_TESTS_ADAPTER'] == 'faraday'
    body = parse(actual[:body], actual[:headers]['Content-Type'])
    body = compact(body)
    return true if expected[:empty] && body.blank?
    expected[:empty] ? body.blank? : body.present?
  end

  def parse(body, type)
    if type.include?('application/json')
      JSON.parse(body)
    elsif type.include?('application/xml')
      Hash.from_xml(body)['Projects']
    elsif type.include?('application/atom')
      Hash.from_xml(body).fetch('feed', {})['entry']
    elsif type.include?('text/plain')
      body
    else
      fail "could not parse #{type}"
    end
  end

  def type?(expected, actual)
    return true if !expected.key?(:type) || redirect?(actual[:status])
    type = actual[:headers]['Content-Type']
    Array(expected[:type]).any? do |expected|
      case expected
      when :img
        type.include?('image/png') || type.include?('image/svg')
      when :json
        type.include?('application/json')
      when :xml
        type.include?('application/xml')
      when :atom
        type.include?('application/atom')
      when :text
        type.include?('text/plain')
      else
        fail "unknown type #{type}"
      end
    end
  end

  def file?(expected, actual)
    return true unless expected.key?(:file)
    actual = actual[:headers]['Content-Disposition']
    expected = %(inline; filename="#{expected[:file]}")
    actual == expected
  end

  def redirect?(status)
    status.to_s[0] == '3'
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
      c.after { |c| c.metadata[:response] = last_response rescue nil }
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
