require 'factory_girl'

Factory = FactoryGirl
def Factory(name, attrs={})
  FactoryGirl.create(name, attrs)
end
