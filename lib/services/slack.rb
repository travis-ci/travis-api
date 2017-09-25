require 'thread'
require 'faraday'
require 'json'

module Services
  module Slack
    extend self
    attr_reader :queue

    def setup
      return unless config = Travis::Config.load.slack and queue.nil?
      @queue = Queue.new
      Thread.new do
        loop do
          payload = { text: @queue.pop }
          Travis::Config.load.slack.to_hash.each do |key, value|
            payload[key] = value unless key.to_s == 'url'
          end
          Faraday.post(config.url, JSON.dump(payload))
        end
      end
    end

    def <<(message)
      @queue.try(:<<, message)
    end
  end
end
