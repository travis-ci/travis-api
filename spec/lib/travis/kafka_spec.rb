describe Travis::Kafka do
  let(:msg)           { "Some message" }
  let(:topic)         { "some.topic" }
  let(:partition_key) { "some_key" }

  context "#deliver_message" do
    before do
      ENV.expects(:fetch).with("KAFKA_URL").returns("192.168.99.100")
    end

    it "sends #deliver_message to a ::Kafka instance" do
      ::Kafka::Client.any_instance.expects(:deliver_message).with(
        msg,
        {
          topic:         topic,
          partition_key: partition_key,
        },
      )

      expect(
        Travis::Kafka.deliver_message(
          msg:           msg,
          topic:         topic,
          partition_key: partition_key,
        )
      ).to be_nil
    end
  end

end
