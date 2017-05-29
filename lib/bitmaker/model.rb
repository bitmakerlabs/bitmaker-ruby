require 'ostruct'

module Bitmaker
  class Model < OpenStruct
    ATTRIBUTES = []
    API_ROOT = '/v1'

    def initialize(attributes)
      whitelist = attributes.select { |k, v| self.class::ATTRIBUTES.include?(k.to_sym) } if self.class::ATTRIBUTES.size > 0
      super(whitelist)
    end

    def serialize(included_models: [])
      JSONAPI::Serializer.serialize(self, include: included_models)
    end

    def resource_path
      self.class.to_s.demodulize.tableize
    end

    def create_path
      [API_ROOT, resource_path].join('/')
    end
  end
end
