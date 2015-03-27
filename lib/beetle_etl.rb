require 'beetle_etl/version'

require 'sequel'
require 'logger'

module BeetleETL

  InvalidConfigurationError = Class.new(StandardError)

  require 'beetle_etl/dsl/dsl'
  require 'beetle_etl/dsl/transformation'
  require 'beetle_etl/dsl/transformation_loader'

  require 'beetle_etl/naming'

  require 'beetle_etl/steps/step'
  require 'beetle_etl/steps/create_stage'
  require 'beetle_etl/steps/transform'
  require 'beetle_etl/steps/map_relations'
  require 'beetle_etl/steps/table_diff'
  require 'beetle_etl/steps/assign_ids'
  require 'beetle_etl/steps/load'
  require 'beetle_etl/steps/drop_stage'

  require 'beetle_etl/step_runner/dependency_resolver'
  require 'beetle_etl/step_runner/async_step_runner'

  require 'beetle_etl/import'
  require 'beetle_etl/reporter'

  class Configuration
    attr_accessor \
      :database_config,
      :database,
      :transformation_file,
      :stage_schema,
      :public_schema,
      :external_source,
      :logger

    def initialize
      @public_schema = 'public'
      @logger = ::Logger.new(STDOUT)
    end
  end

  class << self

    def import
      begin
        report = Import.new.run
        Reporter.new(report).log_summary
        report
      ensure
        @database.disconnect if @database
      end
    end

    def configure
      yield(config)
    end

    def config
      @config ||= Configuration.new
    end

    def logger
      config.logger
    end

    def database
      if config.database
        config.database
      elsif config.database_config
        @database ||= Sequel.connect(config.database_config)
      else
        msg = "Either Sequel connection database_config or a Sequel Database object required"
        raise InvalidConfigurationError.new(msg)
      end
    end

    def reset
      @config = nil
      @database = nil
    end

  end
end
