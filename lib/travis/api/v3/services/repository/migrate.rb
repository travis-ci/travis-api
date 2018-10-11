module Travis::API::V3
  class Services::Repository::Migrate < Service
    # FIXME: This shouldn't be "bar" - we need confirmation on what the topic
    #   should be for beginning the migration
    #
    KAFKA_TOPIC = "essential.repository.migrate"

    def run!
      repository = check_login_and_find(:repository)
      check_access(repository)
      current_user = access_control.user

      owner = repository.owner
      if !Travis::Features.owner_active?(:migrate, owner)
        raise Error.new("Migrating repositories is disabled for #{owner.login}. Please contact Travis CI support for more information.", status: 403)
      end

      Travis::Kafka.deliver_message(
        topic: KAFKA_TOPIC,
        msg: {
          data:     { owner_name: repository.owner_name, name: repository.name },
          metadata: { force_reimport: false }
        },
      )

      Travis.logger.info(
        "Repo Migration Request: Repo ID: #{repository.id}, User: #{current_user.id}"
      )

      result repository
    rescue Kafka::Error => e
      Travis.logger.error(
        "Repo Migration Request Failed -- Exception: #{e.class}, " +
          "Repo ID: #{repository.id}, Repo slug: #{repository.slug}, " +
          "User: #{current_user.id}"
      )

      raise e
    end

    private

    def check_access(repository)
      access_control.permissions(repository).migrate!
    end
  end
end
