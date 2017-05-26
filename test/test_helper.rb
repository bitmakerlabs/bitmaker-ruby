# Suppress Ruby 2.4 warnings
$VERBOSE = nil

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'bitmaker'

require 'minitest/reporters'
require 'minitest/autorun'
require 'mocha/mini_test'
require 'byebug'

require 'webmock/minitest'
require 'timecop'


Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

WebMock.disable_net_connect!
