require 'spec_helper'

require 'rails/all'
require 'rails/test_help'
require 'rspec/rails'

require 'jsonapi-resources'
require 'jsonapi/utils'

require 'support/models'
require 'support/factories'
require 'support/resources'
require 'support/controllers'
require 'support/paginators'

require 'support/shared/jsonapi_errors'
require 'support/shared/jsonapi_request'

require 'test_app'

RSpec.configure do |config|
  config.before(:all) do
    TestApp.draw_app_routes

    %w[posts categories profiles users].each do |table_name|
      ActiveRecord::Base.connection.execute("DELETE FROM #{table_name}; VACUUM;")
    end
  end
end

