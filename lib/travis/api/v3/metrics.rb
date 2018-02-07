require 'metriks'
require 'travis/honeycomb'

module Travis::API::V3
  class Metrics
    class MetriksTracker
      def initialize(prefix: "api.v3")
        @prefix = prefix
      end

      def time(name, duration)
        ::Metriks.timer("#{@prefix}.#{name}").update(duration)
      end

      def mark(name)
        ::Metriks.meter("#{@prefix}.#{name}").mark
      end
    end

    class Processor
      attr_reader :queue, :tracker

      def initialize(queue_size: 1000, tracker: MetriksTracker.new)
        @tracker = tracker
        @queue   = queue_size ? ::SizedQueue.new(queue_size) : ::Queue.new
      end

      def create(**options)
        Metrics.new(self, **options)
      end

      def start
        Thread.new { loop { process(queue.pop) } }
      end

      def process(metrics)
        metrics.process(tracker)
      rescue Exception => e
        $stderr.puts e.message, e.backtrace
      end
    end

    def initialize(processor, time: Time.now)
      @processor  = processor
      @start_time = time
      @name_after = nil
      @ticks      = []
      @success    = nil
      @name       = "unknown".freeze
    end

    def tick(event, time: Time.now)
      @ticks << [event, time]
      self
    end

    def success(**options)
      finish(true, **options)
    end

    def failure(**options)
      finish(false, **options)
    end

    def name_after(factory)
      @name       = nil
      @name_after = factory
      self
    end

    def finish(success, time: Time.now, status: nil)
      @success  = !!success
      @status   = status
      @status ||= success ? 200 : 500
      @end_time = time
      @processor.queue << self
      self
    end

    def name
      @name ||= @name_after.name[/[^:]+::[^:]+$/].underscore.tr(?/.freeze, ?..freeze)
    end

    def process(tracker)
      tracker.mark("status.#{@status}")

      if @success
        process_ticks(tracker)
        tracker.time("#{name}.overall", @end_time - @start_time)
        tracker.mark("#{name}.success")
      else
        tracker.mark("#{name}.failure")
      end
    end

    def process_ticks(tracker)
      start = @start_time
      @ticks.each do |event, time|
        tracker.time("#{name}.#{event}", time - start)
        Travis::Honeycomb.context.add("#{event}_duration_ms", (time - start) * 1000)
        start = time
      end
    end
  end
end
