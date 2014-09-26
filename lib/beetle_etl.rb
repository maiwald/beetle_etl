require 'beetle_etl/version'

require 'sequel'

module BeetleETL

  InvalidConfigurationError = Class.new(StandardError)

  require 'beetle_etl/dsl/dsl'
  require 'beetle_etl/dsl/transformation'
  require 'beetle_etl/dsl/transformation_loader'

  require 'beetle_etl/steps/step'
  require 'beetle_etl/steps/transform'
  require 'beetle_etl/steps/map_relations'
  require 'beetle_etl/steps/table_diff'
  require 'beetle_etl/steps/assign_ids'
  require 'beetle_etl/steps/load'

  require 'beetle_etl/task_runner/dependency_resolver'
  require 'beetle_etl/task_runner/task_runner'

  require 'beetle_etl/state'
  require 'beetle_etl/import'

  class Configuration
    attr_accessor \
      :database_config,
      :database,
      :transformation_file,
      :stage_schema,
      :external_source

    def initialize
      @stage_schema = 'stage'
    end
  end

  class << self

    def import
      state.start_import

      begin
        Import.run
        state.mark_as_succeeded
      rescue Exception => e
        state.mark_as_failed
        raise e
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

    def state
      @state ||= State.new
    end

    def reset
      @config = nil
      @state = nil
      @database = nil
    end

  end
end
