require 'smart_rspec'
require 'factory_girl'
require 'support/helpers'

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods
  config.include Helpers::ResponseParser

  config.define_derived_metadata do |meta|
    meta[:aggregate_failures] = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
end
