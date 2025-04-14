require 'web_translate_it/safe'

if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.start
end

require 'rr'

RSpec.configure do |config|
  config.mock_with :nothing
  config.include RR::DSL

  config.before do
    RR.reset
  end

  config.after do
    RR.verify
  end
end
