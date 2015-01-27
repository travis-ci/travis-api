module Travis::API::V3
  class Queries::Repositories < Query
    params :active, :private, prefix: :repository

    def for_member(user)
      all.joins(:users).where(users: user_condition(user))
    end

    private

    def user_condition(value)
      case value
      when String  then { login: value    }
      when Integer then { id:    value    }
      when ::User  then { id:    value.id }
      else raise WrongParams
      end
    end

    def all
      @all ||= begin
        all = ::Repository
        all = all.where(active:  bool(active))  unless active.nil?
        all = all.where(private: bool(private)) unless private.nil?
        all
      end
    end
  end
end
