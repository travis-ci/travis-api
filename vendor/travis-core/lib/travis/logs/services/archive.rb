begin
  require 'aws/s3'
rescue LoadError => e
end
require 'uri'
require 'active_support/core_ext/hash/slice'
require 'faraday'
require 'travis/support/instrumentation'
require 'travis/notification/instrument'
require 'travis/services/base'

module Travis
  class S3
    class << self
      def setup
        AWS.config(Travis.config.s3.to_h.slice(:access_key_id, :secret_access_key))
      end
    end

    attr_reader :s3, :url

    def initialize(url)
      @s3 = AWS::S3.new
      @url = url
    end

    def store(data)
      object.write(data, content_type: 'text/plain', acl: :public_read)
    end

    def object
      @object ||= bucket.objects[URI.parse(url).path[1..-1]]
    end

    def bucket
      @bucket ||= s3.buckets[URI.parse(url).host]
    end
  end

  module Logs
    module Services
      class Archive < Travis::Services::Base
        class FetchFailed < StandardError
          def initialize(source_url, status, message)
            super("Could not retrieve #{source_url}. Response status: #{status}, message: #{message}")
          end
        end

        class VerificationFailed < StandardError
          def initialize(source_url, target_url, expected, actual)
            super("Expected #{target_url} (from: #{source_url}) to have the content length #{expected.inspect}, but had #{actual.inspect}")
          end
        end

        extend Travis::Instrumentation

        register :archive_log

        attr_reader :log

        def run
          fetch
          store
          verify
          report
        end
        instrument :run

        def source_url
          "https://#{hostname('api')}/logs/#{params[:id]}.txt"
        end

        def report_url
          "https://#{hostname('api')}/logs/#{params[:id]}"
        end

        def target_url
          "http://#{hostname('archive')}/jobs/#{params[:job_id]}/log.txt"
        end

        private

          def fetch
            retrying(:fetch) do
              response = request(:get, source_url)
              if response.status == 200
                @log = response.body.to_s
              else
                raise(FetchFailed.new(source_url, response.status, response.body.to_s))
              end
            end
          end

          def store
            retrying(:store) do
              S3.setup
              s3.store(log)
            end
          end

          def verify
            retrying(:verify) do
              expected = log.bytesize
              actual = request(:head, target_url).headers['content-length'].try(:to_i)
              raise VerificationFailed.new(target_url, source_url, expected, actual) unless expected == actual
            end
          end

          def report
            retrying(:report) do
              request(:put, report_url, { archived_at: Time.now, archive_verified: true }, token: Travis.config.tokens.internal)
            end
          end

          def request(method, url, params = nil, headers = nil, &block)
            http.send(*[method, url, params, headers].compact, &block)
          rescue Faraday::Error => e
            puts "Exception while trying to #{method.inspect}: #{source_url}:"
            puts e.message, e.backtrace
            raise e
          end

          def http
            Faraday.new(ssl: Travis.config.ssl.to_h.compact) do |f|
              f.request :url_encoded
              f.adapter :net_http
            end
          end

          def s3
            S3.new(target_url)
          end

          def hostname(name)
            "#{name}#{'-staging' if Travis.env == 'staging'}.#{Travis.config.host.split('.')[-2, 2].join('.')}"
          end

          def retrying(header, times = 5)
            yield
          rescue => e
            count ||= 0
            if times > (count += 1)
              puts "[#{header}] retry #{count} because: #{e.message}"
              Travis::Instrumentation.meter("#{self.class.name.underscore.gsub("/", ".")}.retries.#{header}")
              sleep count * 3 unless params[:no_sleep]
              retry
            else
              raise
            end
          end

          class Instrument < Notification::Instrument
            def run_completed
              publish(
                msg: "for <Log id=#{target.params[:id]}> (to: #{target.target_url})",
                source_url: target.source_url,
                target_url: target.target_url,
                object_type: 'Log',
                object_id: target.params[:id]
              )
            end
          end
          Instrument.attach_to(self)
      end
    end
  end
end
