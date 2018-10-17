require "kafka"

module Travis
  class Kafka
    class << self

      def deliver_message(msg:, topic:, partition_key: nil)
        kafka.deliver_message(msg, topic: "#{ENV['KAFKA_PREFIX']}#{topic}", partition_key: partition_key)
      end

      private

      def kafka
        @_kafka ||= ::Kafka.new(
          seed_brokers: ENV.fetch('KAFKA_URL'),
          client_id:    "travis_api",
          ssl_ca_cert_file_path: tmp_ca_file.path,
          ssl_client_cert:       ENV.fetch('KAFKA_CLIENT_CERT'),
          ssl_client_cert_key:   ENV.fetch('KAFKA_CLIENT_CERT_KEY'),
        )
      end

      def tmp_ca_file
        @_tmp_ca_file ||= create_tmp_ca_file
      end

      def create_tmp_ca_file
        tmp_file = Tempfile.new('ca_certs')
        tmp_file.write(ENV.fetch('KAFKA_TRUSTED_CERT'))
        tmp_file.close

        tmp_file
      end
    end
  end
end
