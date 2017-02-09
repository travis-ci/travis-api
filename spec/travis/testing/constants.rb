Travis::API::V3::Models.constants.each do |constant|
  Object.const_set(constant, Travis::API::V3::Models.const_get(constant))
end
