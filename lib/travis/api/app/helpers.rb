require 'travis/api/app'

class Travis::Api::App
  # Namespace for helpers.
  module Helpers
    Dir.glob("#{__dir__}/helpers/*.rb").each { |f| require f[%r[(?<=lib/).+(?=\.rb$)]] }
  end
end
