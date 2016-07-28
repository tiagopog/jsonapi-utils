module Exceptions
  class MyCustomError < ::JSONAPI::Exceptions::Error
    attr_accessor :object

    def initialize(object)
      @object = object
    end

    def errors
      [JSONAPI::Error.new(
        code: '125',
        status: :unprocessable_entity,
        id: 'my_custom_validation_error',
        title: 'My custom error message'
      )]
    end
  end
end
