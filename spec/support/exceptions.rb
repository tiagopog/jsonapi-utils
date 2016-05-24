module Exceptions
  class ActiveRecordError < ::JSONAPI::Exceptions::Error
    attr_accessor :object

    def initialize(object)
      @object = object
    end

    def errors
      [JSONAPI::Error.new(
        code: 125,
        status: :unprocessable_entity,
        title: "Can't change this #{@object.class.name}",
        detail: @object.errors)]
    end
  end
end
