require_relative '../lib/tom_hanks.rb'
require_relative 'support/connection_helpers.rb'

RSpec.configure do |config|

  config.include SpecSupport::ConnectionHelpers
  config.backtrace_exclusion_patterns = [/rspec-core/]

  config.around(:each) do |example|
    test_connection.transaction do
      example.run
      # force a rollback
      raise Sequel::Error::Rollback
    end
  end

end

