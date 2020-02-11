require 'bundler/setup'
require 'pry-byebug'

require 'simplecov'
SimpleCov.start 'rails' do
  minimum_coverage 85
  add_filter 'lib/apress/turbo_pages.rb'
  add_filter 'lib/apress/turbo_pages/tasks'
  add_filter 'lib/apress/turbo_pages/version.rb'
  add_filter 'lib/apress/turbo_pages/engine.rb'
  add_filter 'db/migrate'
end

require File.expand_path('../../spec/internal/config/boot', __FILE__)

require 'rspec/rails'
require 'webmock/rspec'
require 'factory_girl_rails'
require 'shoulda-matchers'
require 'mock_redis'
require 'timecop'
require 'vcr'

redis = MockRedis.new
Redis.current = redis
Resque.redis = redis

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods
  config.before { Redis.current.flushdb }
end

VCR.configure do |c|
  c.ignore_hosts '127.0.0.1', 'localhost', '::1'
  c.cassette_library_dir = 'spec/cassettes'
  c.hook_into :webmock

  c.configure_rspec_metadata!
end

Combustion.initialize! :all
