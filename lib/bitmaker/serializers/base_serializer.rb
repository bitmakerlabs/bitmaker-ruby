module Bitmaker
  class BaseSerializer
    include JSONAPI::Serializer

    def type
      object.class.name.demodulize.tableize.underscore
    end

    def format_name(attribute_name)
      attribute_name.to_s.underscore
    end
  end
end
