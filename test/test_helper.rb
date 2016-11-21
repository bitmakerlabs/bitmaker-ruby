$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'bitmaker'

require 'minitest/spec'
require 'minitest/reporters'
require 'minitest/autorun'

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new
