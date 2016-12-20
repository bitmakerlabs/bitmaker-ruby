require 'active_support'
require 'active_support/core_ext/string/inflections'
require 'jsonapi-serializers'

require "bitmaker/version"

require "bitmaker/serializers/base_serializer"
require "bitmaker/serializers/lead_serializer"
require "bitmaker/serializers/website_activity_serializer"

require "bitmaker/model"
require "bitmaker/models/lead"
require "bitmaker/models/website_activity"

require "bitmaker/client"
