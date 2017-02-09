module Scenario
  extend self
  def default
    load_scenario(:default)
  end

  def load_scenario(scenario)
    @sources           ||= {}
    @sources[scenario] ||= File.read("#{__dir__}/../../scenarios/#{scenario}.sql")
    ActiveRecord::Base.connection.execute(@sources[scenario])
  end
end
