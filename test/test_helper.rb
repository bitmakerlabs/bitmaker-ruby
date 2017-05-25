$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'bitmaker'

require 'minitest/reporters'
require 'minitest/autorun'
require 'minitest/byebug' if ENV['DEBUG']

require 'webmock/minitest'
require 'timecop'


Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

WebMock.disable_net_connect!
