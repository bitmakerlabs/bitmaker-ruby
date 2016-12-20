require 'ostruct'

module Bitmaker
  class Model < OpenStruct
    ATTRIBUTES = []
    API_ROOT = '/api/v1'

    def initialize(attributes)
      whitelist = attributes.select { |k, v| self.class::ATTRIBUTES.include?(k) } if self.class::ATTRIBUTES.size > 0
      super(whitelist)
    end

    def serialize(included_models: [])
      JSONAPI::Serializer.serialize(self, include: included_models)
    end

    def create_path
      [API_ROOT, self.class.to_s.demodulize.tableize].join('/')
    end
  end
end
