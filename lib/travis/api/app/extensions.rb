require 'travis/api/app'

class Travis::Api::App
  # Namespace for Sinatra extensions.
  module Extensions
    Dir.glob("#{__dir__}/extensions/*.rb").each { |f| require f[%r[(?<=lib/).+(?=\.rb$)]] }
  end
end
