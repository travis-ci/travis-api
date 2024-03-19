module Travis::API::V3
  class Queries::Broadcasts < Query
    params :active, prefix: :broadcast

    def initialize(params, main_type, **args)
      super
      self.active = "true".freeze if active.nil?
    end

    def for_user(user)
      all.where(<<-SQL, 'Organization'.freeze, user.organization_ids, 'User'.freeze, user.id, 'Repository'.freeze, user.repository_ids)
        recipient_type IS NULL OR
        recipient_type = ? AND recipient_id IN(?) OR
        recipient_type = ? AND recipient_id = ? OR
        recipient_type = ? AND recipient_id IN (?)
      SQL
    end

    def all
      @all ||= filter(Models::Broadcast)
    end

    def filter(list)
      active = list(self.active).map { |e| bool(e) }

      if active.include? true
        list = list.active unless active.include? false
      else
        list = list.inactive
      end

      list
    end
  end
end
