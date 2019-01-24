require 'smart_rspec'
require 'factory_bot'
require 'support/helpers'

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
  config.include Helpers::ResponseParser

  config.define_derived_metadata do |meta|
    meta[:aggregate_failures] = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
end
