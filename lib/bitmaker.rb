require 'active_support'
require 'active_support/core_ext/string/inflections'
require 'jsonapi-serializers'

require "bitmaker/version"

require "bitmaker/model"
require "bitmaker/models/lead"
require "bitmaker/models/inquiry"

require "bitmaker/serializers/base_serializer"
require "bitmaker/serializers/lead_serializer"
require "bitmaker/serializers/inquiry_serializer"

require "bitmaker/client"
