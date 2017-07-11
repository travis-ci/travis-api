module Travis::API::V3
  class Queries::UserSetting < Query
    params :name, :value, prefix: :setting

    def find(repository)
      repository.user_settings.read(_name)
    end

    def update(repository)
      repository.user_settings.update(_name, _value)
    end

    private

    def _name
      setting_params.key?('name') ? setting_params['name'] : setting_params['name']
    end

    def _value
      setting_params.key?('value') ? setting_params['value'] : setting_params['value']
    end
  end
end
