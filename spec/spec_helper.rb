require "codeclimate-test-reporter"
CodeClimate::TestReporter.start

require_relative '../lib/beetle_etl.rb'
require_relative 'support/database_helpers.rb'

RSpec.configure do |config|

  config.include SpecSupport::DatabaseHelpers
  config.backtrace_exclusion_patterns = [/rspec-core/]

  config.around(:each) do |example|
    BeetleETL.reset
    if example.metadata[:feature]
      example.run
    else
      test_database.transaction do
        example.run
        raise Sequel::Error::Rollback
      end
    end
  end

end

