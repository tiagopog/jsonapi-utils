##
# General configs
##

RSpec.configure do |config|
  config.before(:all) do
    %w[posts categories profiles users].each do |table_name|
      ActiveRecord::Base.connection.execute("DELETE FROM #{table_name}; VACUUM;")
    end
  end
end

JSONAPI.configure do |config|
  config.json_key_format = :underscored_key

  config.allow_include = true
  config.allow_sort = true
  config.allow_filter = true

  config.default_page_size = 10
  config.maximum_page_size = 10
  config.default_paginator = :paged
  config.top_level_links_include_pagination = true

  config.top_level_meta_include_record_count = true
  config.top_level_meta_record_count_key = :record_count
end

##
# Rails application
##

Rails.env = 'test'
puts "Rails version: #{Rails.version}"

class TestApp < Rails::Application
  config.eager_load = false
  config.root = File.dirname(__FILE__)
  config.session_store :cookie_store, key: 'session'
  config.secret_key_base = 'secret'

  # Raise errors on unsupported parameters
  config.action_controller.action_on_unpermitted_parameters = :log

  ActiveRecord::Schema.verbose = false
  config.active_record.schema_format = :none
  config.active_support.test_order = :random

  # Turn off millisecond precision to maintain Rails 4.0 and 4.1 compatibility in test results
  Rails::VERSION::MAJOR >= 4 && Rails::VERSION::MINOR >= 1 &&
    ActiveSupport::JSON::Encoding.time_precision = 0

  I18n.enforce_available_locales = false
  I18n.available_locales = [:en, :ru]
  I18n.default_locale = :en
  I18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}')]
end

Dir[Rails.root.join('support/shared/**/*.rb')].each { |f| require f }

##
# Routes
##

JSONAPI.configuration.route_format = :dasherized_route

TestApp.routes.draw do
  jsonapi_resources :users do
    jsonapi_links :profile
    jsonapi_resources :posts, shallow: true
  end

  jsonapi_resource :profile

  patch :update_with_error_on_base, to: 'posts#update_with_error_on_base'

  get :index_with_hash, to: 'posts#index_with_hash'
  get :show_with_hash,  to: 'posts#show_with_hash'
end
